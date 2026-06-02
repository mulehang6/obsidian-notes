# 1. 什么是Redis？

Redis是一种基于键值对的NoSQL数据库，它将数组存储在内存中，相比存储在磁盘中的关系型数据库，它的速度快很多，基本上能达到微妙级的响应

索引在一些对性能要求很高的场景下，都会用到Redis，例如缓存热点数据、防止接口刷爆等。

不仅如此，Redis还能将数据持久化，将内存中的数据异步落盘，防止服务器宕机后数据丢失

# 2. Redis和MySQL的区别？

Redis是基于键值对的非关系型数据库，数据存储在内存中，而MySQL是典型的关系型数据库，将数据存储在磁盘中

# 3. 部署过Redis吗？

最简单版：我只在本地部署过单机版，下载安装包后解压运行命令即可

# 4. 用过哪些缓存数据库，除了Redis？

还用过Caffeine，通常作为二级缓存来减少Redis的压力

# 5. Redis可以用来做什么？

做缓存，减轻如MySQL数据库的压力，将高频访问的信息存储在Redis中，缓存命中则直接返回结果，未命中再查MySQL

ZSet还可以用来做热点排行榜，通过score字段进行排序，取前N个元素，就能实现TopN的功能

SETNX命令或者Redission还能实现分布式锁，确保同一时间只有一个节点可以持有锁；为了防止出现死锁，还可以加上超时时间，到期后自动释放；并且最好开启一个监听线程，当任务完成时给锁自动续期。

如果是秒杀接口，还可以使用Lua脚本来实现令牌桶算法，限制每秒只能处理N个请求
```lua
-- KEYS[1]: 令牌桶的key
-- ARGV[1]: 桶容量
-- ARGV[2]: 令牌生成速率（每秒）
-- ARGV[3]: 当前时间戳（秒）

local bucket = redis.call('HMGET', KEYS[1], 'tokens', 'timestamp')
local tokens = tonumber(bucket[1]) or ARGV[1]
local last_time = tonumber(bucket[2]) or ARGV[3]

local rate = tonumber(ARGV[2])
local capacity = tonumber(ARGV[1])
local now = tonumber(ARGV[3])

-- 计算新令牌数
local delta = math.max(0, now - last_time)
local add_tokens = delta * rate
tokens = math.min(capacity, tokens + add_tokens)
last_time = now

local allowed = 0
if tokens >= 1 then
    tokens = tokens - 1
    allowed = 1
end

redis.call('HMSET', KEYS[1], 'tokens', tokens, 'timestamp', last_time)
redis.call('EXPIRE', KEYS[1], 3600) -- 过期时间可自定义

return allowed
```

在Java中调用Lua脚本

```java
// 令牌桶参数
int capacity = 10; // 桶容量
int rate = 2;      // 每秒2个令牌
long now = System.currentTimeMillis() / 1000;
String key = "token_bucket:user:123";

// 调用 Lua 脚本，返回 1 表示通过，0 表示被限流
Long allowed = (Long) redis.eval(luaScript, 1, key, String.valueOf(capacity), String.valueOf(rate), String.valueOf(now));
```

# 6. Redis做缓存要考虑哪些问题？在业务方面呢？

一类是经典的缓存系统设计问题(穿透，击穿，雪崩)，另一类是与业务逻辑紧密相关的业务缓存问题(数据一致性，缓存粒度等)。

当修改了数据库的数据之后，如何保证缓存里的数据也同步更新，不会出现脏数据

另一个就是应该缓存的是完整的、包含各种关联信息的对象，还是只缓存重要的字段

## 1. 穿透

查询一个redis和数据库中都不存在的数据，大量请求绕过redis打到数据库

解决方案：
- 缓存空值
  - 优点：简单
  - 缺点：如果有大量这种请求，那么会浪费redis的空间。如果有数据同步的服务，可能会导致空值真的存储带数据库
- 布隆过滤器：把数据库中存在id的提前放入布隆过滤器
  - 优点：适合防止恶意请求大量访问不存在的key
  - 缺点：布隆过滤器有缺陷，只有“可能存在”和“一定不存在”这两种情况是完全可信的

## 2. 击穿

某个热点key在某一时刻突然失效，同时大量请求访问这个key，导致这些请求全都打到数据库

核心不在大量key失效，而是某一个key失效

解决方案：
- 互斥锁：缓存失效后，仅允许一个线程去查数据库并重建缓存，其他线程等待或者稍后重试
  伪流程：
  ```text
  查 Redis，没有数据
  尝试获取锁
  获取锁成功 -> 查 DB -> 写入 Redis -> 释放锁
  获取锁失败 -> 等待一会儿再查 Redis
  ```
  常见实现：SETNX lock:key 1 EX 10
- 逻辑过期：redis中的数据不设置真正的过期时间，而是在value里存一个逻辑过期时间，查询时，如果没过期就直接返回，如果过期，先返回旧数据，然后再异步重建缓存
  - 优点：用户请求不会被阻塞，性能好
  - 缺点：会出现短暂的数据不一致
- 热点key永不过期：对于特别核心的热点数据，可以不设置过期时间，改成后台定时刷新，例如首页配置、热门榜单、秒杀活动信息等

## 3. 雪崩

大量key在同一时间过期，或者redis整体宕机，导致大量请求同时打到数据库

核心：不是一个热点key失效，而是大量，或者redis服务不可用

解决方案：
- 过期时间加随机值：在原来的过期时间基础上加上随机的0~10分钟，或者其他随机时间
- redis高可用：使用redis主从，哨兵，cluster集群，避免redis单点故障
- 限流，降级，熔断
- 缓存预热：系统上线前，提前把某个热点数据加载到redis中

# 7. Redis有哪些数据类型？

五种基本数据类型：字符串、列表，哈希表，集合，有序集合 
三种扩展数据类型：Bitmap(用于位操作)，HyperLogLog(用于基数估计)，GEO(支持存储和查询地理坐标)
[[Redis数据类型.excalidraw]]

## Redis GEO 查询附近商家
```java
public class NearbyShopService {
    private Jedis jedis;
    private static final String SHOP_KEY = "shops:geo";
    
    // 添加商铺
    public void addShop(String shopId, double longitude, double latitude) {
        jedis.geoadd(SHOP_KEY, longitude, latitude, shopId);
    }
    
    // 查询附近的商铺
    public List<GeoRadiusResponse> getNearbyShops(
            double longitude, 
            double latitude, 
            double radiusKm) {
        return jedis.georadius(SHOP_KEY, 
                             longitude, 
                             latitude, 
                             radiusKm, 
                             GeoUnit.KM, 
                             GeoRadiusParam.geoRadiusParam()
                                         .withCoord()
                                         .withDist()
                                         .sortAscending()
                                         .count(20));
    }
    
    // 计算两个商铺之间的距离
    public double getShopDistance(String shop1Id, String shop2Id) {
        return jedis.geodist(SHOP_KEY, 
                           shop1Id, 
                           shop2Id, 
                           GeoUnit.KILOMETERS);
    }
}
```

# 30. 布隆过滤器

布隆过滤器是一种空间利用率极高的概率性数据结构，用于快速判断一个元素是否在一个集合中。它的特点是能够以极小的内存消耗，判断一个元素“一定不在集合中”或者“可能在集合中”，常用来解决Redis缓存穿透(请求的数据根本不存在，数据库和缓存都查不到)。

## 布隆过滤器存在误判吗？

是的，存在。

可能会误认为某个数据在集合中，但是如果布隆过滤器认为数据不在集合中，那就一定不在。

误判产生的原因是哈希冲突。在布隆过滤器中，多个元素可能映射到相同的位置，随着布隆过滤器中添加的元素不断增加，位数组中的1也越来越多，发生哈希冲突的概率也随之增加，误判率也就随之上升。