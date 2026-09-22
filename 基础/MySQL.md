# MySQL 面经

> 这份面经按“能回答面试官追问”的标准整理，不只给结论，也补上原理、常见误区和项目中的真实例子。  
> 项目背景：`mulehang6/tech-community`，Spring Boot + MyBatis-Plus + MySQL + Redis + Elasticsearch 等。

---

## 1. InnoDB 为什么使用 B+ 树，而不是二叉搜索树、红黑树或者 B 树？

### 面试回答

InnoDB 的索引主要使用 B+ 树，核心原因是数据库索引存储在页中，查询成本很大一部分来自磁盘或页访问次数。B+ 树每个非叶子节点可以存很多索引项，因此树的扇出很大、树高很低。即使数据量很大，通常也只需要访问少量页。

相比之下：

- 普通二叉搜索树在极端情况下可能退化成链表。
- 红黑树虽然能保持平衡，但每个节点只有两个孩子，同样数据量下树会高很多，不适合磁盘页这种块存储结构。
- B 树的非叶子节点也保存完整记录，会占用更多空间，导致一个页能容纳的索引项更少，扇出降低。
- B+ 树把完整记录放在叶子节点，非叶子节点主要保存键和子节点指针，一个页可以放更多索引项。
- B+ 树的叶子节点按照键值有序，并通过链表相连，很适合范围查询和排序。

### 为什么“树矮”很重要

假设一页是 16 KB，一个非叶子页能放上千个索引项，那么三层或四层 B+ 树就可以管理非常大的数据量。

查询过程可以粗略理解成：

```text
根页
 ↓
中间页
 ↓
叶子页
```

所以数据库更关注“访问几个页”，而不是单纯比较了几次。

### 常见追问

**为什么 B+ 树适合范围查询？**

因为叶子节点有序且相互连接。找到范围起点以后，可以沿叶子节点继续向后扫描，不需要反复从根节点重新查。

**Hash 索引不是等值查询更快吗？**

Hash 更适合精确等值查询，但不支持天然的范围查询和排序，也不能利用最左前缀做类似 B+ 树的范围扫描。InnoDB 的主索引结构仍然是 B+ 树。

---

## 2. 什么叫聚簇索引？什么叫二级索引？

### 面试回答

InnoDB 中，表数据本身按照主键索引组织，所以主键索引通常称为聚簇索引。

聚簇索引的叶子节点保存完整行数据：

```text
主键值
+
这一行的其他列
```

而普通索引、唯一索引等非主键索引属于二级索引。二级索引叶子节点通常保存：

```text
二级索引列
+
对应行的主键值
```

比如：

```sql
CREATE TABLE article (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(120),
    INDEX idx_user_id(user_id)
);
```

聚簇索引：

```text
id B+Tree
叶子节点 -> 完整 article 行
```

二级索引：

```text
user_id B+Tree
叶子节点 -> user_id + id
```

### 如果表没有显式主键呢？

InnoDB 会优先选择第一个 `UNIQUE NOT NULL` 索引作为聚簇索引。如果也没有合适的唯一非空索引，InnoDB 会生成隐藏的行 ID 来组织聚簇索引。

所以实际建表时通常建议显式设计稳定、短小的主键。

---

## 3. `SELECT * FROM user WHERE name = ?` 使用二级索引以后为什么可能还需要回表？

### 面试回答

因为二级索引叶子节点通常没有这一行的全部字段，只保存二级索引列和主键值。

例如：

```sql
CREATE INDEX idx_name ON user(user_name);
```

执行：

```sql
SELECT *
FROM user
WHERE user_name = 'mulehang';
```

大致流程是：

```text
idx_name 二级索引
 ↓
找到 user_name = 'mulehang'
 ↓
拿到对应主键 id
 ↓
再去主键聚簇索引
 ↓
取完整行
```

第二次根据主键查聚簇索引的过程就叫回表。

### 为什么回表会影响性能？

如果命中结果只有一两行，通常不是问题。

如果二级索引一次命中几十万行，又需要读取很多额外列，就可能发生大量随机回表访问。此时优化器甚至可能认为直接全表扫描成本更低。

### 项目联系

比如文章表如果只对 `user_id` 建普通索引：

```sql
SELECT *
FROM article
WHERE user_id = ?;
```

如果某作者文章很多，查询又取大量字段，就会产生很多回表。

---

## 4. 什么是覆盖索引？

### 面试回答

如果一条 SQL 需要的字段都可以直接从某个索引中取得，就不需要再回聚簇索引读取完整行，这种情况通常称为覆盖索引。

例如：

```sql
CREATE INDEX idx_user_status
ON article(user_id, status);
```

查询：

```sql
SELECT user_id, status
FROM article
WHERE user_id = 10;
```

需要返回的字段都在索引里，所以可以直接从二级索引完成查询。

如果只查主键：

```sql
SELECT id
FROM article
WHERE user_id = 10;
```

普通二级索引叶子节点本身就保存主键，因此也可能形成覆盖。

### 覆盖索引为什么快？

主要少了一次或多次回表访问，同时索引页通常比完整数据页更紧凑，一次 IO 能读取更多索引记录。

### 注意

不要为了覆盖所有查询，把几十个列全部塞进联合索引。索引越宽：

- 占空间越大
- B+ 树页能容纳的记录越少
- 更新索引成本越高
- Buffer Pool 的利用率也可能变差

覆盖索引是手段，不是目标。

---

## 5. 联合索引 `(a,b,c)`，`WHERE a = ? AND c = ?` 怎么用索引？

### 面试回答

假设有：

```sql
INDEX idx_abc(a, b, c)
```

B+ 树的排序规则可以理解成：

```text
先按 a 排
a 相同，再按 b 排
b 相同，再按 c 排
```

查询：

```sql
WHERE a = ? AND c = ?
```

`a` 可以用于定位索引范围。

但是由于中间缺少 `b` 条件，`c` 通常不能继续缩小 B+ 树最初的查找范围，也就是不能按 `(a,c)` 直接定位。

不过这不等于 `c` 完全没用。现代 MySQL 可能利用 Index Condition Pushdown 等机制，在索引层进一步过滤 `c`，减少回表数量。

### 面试里最好这么说

不要简单回答：

> c 完全失效。

更准确的是：

> `a` 能用于索引定位。由于跳过了 `b`，`c` 一般不能继续形成有效的联合索引查找前缀，但仍可能参与索引条件过滤。

---

## 6. 联合索引 `(a,b,c)`，`WHERE b = ? AND c = ?` 呢？

### 面试回答

通常不能利用 `(a,b,c)` 的最左前缀直接定位，因为缺少第一列 `a`。

原因还是联合索引的整体排序方式：

```text
a
 ↓
b
 ↓
c
```

只有在 `a` 相同的数据内部，`b` 才整体有序。

不知道 `a` 时，不能直接根据 `b` 定位连续区间。

### 但是要注意 MySQL 优化器

某些版本和场景下，MySQL 可能采用 Skip Scan 等优化方式利用索引的一部分能力，所以面试不要说“永远绝对不会使用这个索引”。

更稳妥的回答是：

> 从经典最左前缀角度看，缺少第一列以后无法高效使用这个联合索引做常规范围定位。实际是否使用、如何使用，要看版本、数据分布和执行计划。

---

## 7. 为什么 `LIKE '%abc%'` 普通 B+ 树索引效果差？

### 面试回答

B+ 树索引按照字符串从左到右的值排序。

例如：

```sql
WHERE title LIKE 'MySQL%'
```

数据库知道前缀是 `MySQL`，可以定位到一个连续范围。

但：

```sql
WHERE title LIKE '%MySQL%'
```

前缀未知。

可能匹配：

```text
学习MySQL
深入MySQL原理
MySQL实战
Java与MySQL
```

这些值在 B+ 树中并不一定处于一个能通过前缀直接定位的连续范围，因此普通 B+ 树索引很难高效完成这种“任意位置包含”的搜索。

### 项目联系

`tech-community` 的文章搜索兜底 SQL 中存在：

```sql
a.title LIKE CONCAT('%', #{keyword}, '%')
OR a.short_title LIKE CONCAT('%', #{keyword}, '%')
OR a.summary LIKE CONCAT('%', #{keyword}, '%')
```

甚至可能查正文。

这种搜索在数据量小时可以接受，但数据量上来后更适合 Elasticsearch 这类倒排索引系统。

---

## 8. `WHERE DATE(create_time) = ?` 为什么可能不如范围查询？

### 面试回答

假设有索引：

```sql
INDEX idx_create_time(create_time)
```

写成：

```sql
WHERE DATE(create_time) = '2026-09-22'
```

相当于对索引列执行函数计算。传统情况下，数据库很难直接按照原始 `create_time` 的排序值定位范围，可能导致索引利用效果变差。

更推荐写成：

```sql
WHERE create_time >= '2026-09-22 00:00:00'
  AND create_time <  '2026-09-23 00:00:00'
```

这样可以直接利用 `create_time` 的有序性做范围扫描。

### 补充

现代 MySQL 也支持函数索引或生成列等方式解决部分函数查询问题，所以“对索引列使用函数就必然不走索引”不是绝对规律。

面试时应该说：

> 普通索引下，对列做函数转换往往不利于直接利用原始索引排序。如果业务长期需要按某个函数结果查询，可以考虑改写范围条件、生成列或函数索引，并通过 EXPLAIN 验证。

---

## 9. 事务的 ACID 分别是什么？

### 面试回答

事务的 ACID 包括原子性、一致性、隔离性和持久性。

### Atomicity，原子性

一个事务里的操作要么全部成功，要么全部失败。

比如注册用户：

```text
插入 user
插入 user_info
写入其他绑定信息
```

如果中途失败，前面的数据库修改也应该回滚。

InnoDB 的 Undo Log 是实现回滚的重要基础。

### Consistency，一致性

事务执行前后，数据库都应该满足定义好的约束和业务规则。

例如：

- 主键唯一
- 唯一索引不能冲突
- 业务状态保持合法
- 转账前后总金额符合业务规则

一致性不是单靠某一个日志实现，而是原子性、隔离性、持久性以及业务代码、约束共同保证的结果。

### Isolation，隔离性

多个事务并发执行时，一个事务不应该看到另一个事务不该被它看到的中间状态。

InnoDB 主要通过：

```text
MVCC
锁
事务隔离级别
```

处理并发访问。

### Durability，持久性

事务 `COMMIT` 成功后，即使数据库进程崩溃或机器异常，已经提交的数据也应该能够恢复。

Redo Log 是 InnoDB 实现崩溃恢复的重要机制。

---

## 10. InnoDB 默认事务隔离级别是什么？四种隔离级别分别是什么？

### 面试回答

InnoDB 默认事务隔离级别是：

```text
REPEATABLE READ
```

也就是可重复读，简称 RR。

SQL 标准中常见的四种隔离级别是：

| 隔离级别 | 脏读 | 不可重复读 | 幻读 |
|---|---|---|---|
| READ UNCOMMITTED | 可能 | 可能 | 可能 |
| READ COMMITTED | 避免 | 可能 | 可能 |
| REPEATABLE READ | 避免 | 避免 | 标准定义下仍需讨论，InnoDB 有额外机制处理 |
| SERIALIZABLE | 避免 | 避免 | 避免 |

### 四个级别

#### READ UNCOMMITTED 读未提交

事务可以读取其他事务尚未提交的数据，隔离性最低。

#### READ COMMITTED 读已提交

每次普通一致性读只能看到当时已经提交的数据。

可以避免脏读，但同一个事务前后两次查询可能看到不同提交结果。

#### REPEATABLE READ 可重复读

同一个事务中的普通一致性读通常保持在同一个快照上，因此能解决不可重复读问题。

InnoDB 还通过 MVCC、Next-Key Lock 等机制处理幻读相关问题。

#### SERIALIZABLE 可串行化

隔离性最高。普通查询也可能需要更强的锁语义，并发能力最低。

---

## 11. 什么是脏读、不可重复读和幻读？

### 面试回答

### 脏读

事务 A 修改了一条数据，但还没有提交。

事务 B 就读到了这个修改结果。

之后事务 A 回滚，那么事务 B 刚才读到的是一个从未真正提交的数据。

例子：

```text
A: UPDATE age = 50
A: 还没 COMMIT

B: SELECT age -> 50

A: ROLLBACK
```

B 读到的 50 就是脏数据。

### 不可重复读

同一个事务内，对同一条记录或同一查询条件进行多次普通读取，前后看到已存在记录的值不同。

例如：

```text
A 第一次读：age = 18
B 修改 age = 50 并提交
A 第二次读：age = 50
```

重点通常是“已有行的内容发生变化”。

### 幻读

同一个事务中，按照同一个范围条件查询，第二次看到了一些第一次不存在的行，或者原本存在的行消失了。

例如：

```sql
SELECT * FROM article WHERE user_id = 10;
```

第一次返回 3 行。

其他事务插入一条 `user_id = 10` 的文章并提交。

第二次相同条件查询看到了新行。

这就是典型幻读。

### 一个容易背错的点

幻读不能只理解成“数量变了”。

更准确的是：

> 同一个谓词范围内，结果集合中出现了新的行或少了行。

条数变化只是常见表现。

---

## 12. READ COMMITTED 和 REPEATABLE READ 最大区别是什么？

### 面试回答

从 InnoDB 的普通一致性读角度看，最关键的区别之一是 Read View 的生成和复用方式。

### READ COMMITTED

通常每次一致性读都会基于当时的已提交状态建立新的 Read View。

所以：

```text
A 第一次 SELECT
B 修改并 COMMIT
A 第二次 SELECT
```

A 第二次查询可能看到 B 已经提交的新值。

所以 RC 可能出现不可重复读。

### REPEATABLE READ

一个事务第一次一致性读建立快照后，后续普通一致性读通常继续使用这个快照。

所以：

```text
A 第一次 SELECT -> 18
B UPDATE -> 50, COMMIT
A 第二次普通 SELECT -> 通常仍然看到 18
```

这就是“可重复读”。

### 需要注意

`SELECT ... FOR UPDATE`、`UPDATE`、`DELETE` 属于需要访问当前数据的锁定读或当前读场景，不能简单套用普通快照读的行为。

---

## 13. MVCC 是怎么实现的？

### 面试回答

MVCC 全称 Multi-Version Concurrency Control，多版本并发控制。

它解决的核心问题是：

> 普通读和写如果全部依赖互斥锁，并发性能会很差。MVCC 让事务可以读取合适的历史版本，从而减少读写之间的阻塞。

InnoDB 的 MVCC 可以抓住几个关键词：

```text
隐藏事务信息
Undo Log
历史版本
Read View
可见性判断
```

可以把一条记录理解成存在多个逻辑版本：

```text
当前版本
   ↓ undo
上一个版本
   ↓ undo
更老版本
```

当事务执行普通一致性读时：

1. 获取或使用 Read View。
2. 检查当前版本对应的事务对自己是否可见。
3. 如果可见，直接读取。
4. 如果不可见，根据 Undo Log 找更老的版本。
5. 继续判断，直到找到可见版本或确认没有可见版本。

### 为什么 MVCC 能提高并发？

因为很多普通 `SELECT` 不需要给读取的数据加排他锁，也不需要等待写事务提交。

读事务可以读旧版本，写事务继续修改新版本。

---

## 14. Undo Log 在 MVCC 中是干什么的？

### 面试回答

Undo Log 主要有两个非常重要的作用。

### 1. 事务回滚

如果事务执行：

```sql
UPDATE article
SET title = 'B'
WHERE id = 1;
```

原来 title 是 `A`。

事务最后回滚时，InnoDB 需要根据 Undo 信息恢复旧值。

### 2. MVCC 构造历史版本

其他事务如果按照自己的 Read View 不能看到当前新版本，就可以沿 Undo 信息找到更旧的数据版本。

所以可以粗略理解成：

```text
Undo Log
=
回滚需要的旧值信息
+
MVCC 历史版本链的重要来源
```

### Undo Log 会永久保存吗？

不会。

当系统确认某些历史版本已经不可能再被活跃事务访问后，可以由 Purge 相关机制逐步清理。

如果存在持续很久的长事务，旧版本可能长时间无法清理，导致 Undo 空间膨胀，所以长事务是线上数据库需要关注的问题。

---

## 15. Read View 是什么？

### 面试回答

Read View 可以理解成：

> 一个事务在进行一致性读时，用来判断“哪些事务版本对我可见”的快照规则。

不要把它只背成几个字段。

它真正要解决的问题是：

```text
当前这条记录由事务 X 修改
        ↓
事务 X 的版本对我可见吗？
        ↓
可见 -> 读当前版本
不可见 -> 找 Undo 中更老版本
```

Read View 会记录和当前活跃事务有关的信息，例如：

- 创建快照时活跃事务的集合
- 活跃事务 ID 的边界信息
- 当前事务自身的信息

### 可见性可以怎么理解？

如果某个数据版本在当前事务的快照建立前就已经提交，通常是可见的。

如果对应事务在快照建立时仍然活跃，或者属于未来事务产生的版本，则通常不可见，需要继续向旧版本寻找。

### 面试重点

不要死背字段比较公式后却说不清目的。

先说：

> Read View 决定当前事务能看到哪些版本。

再解释 Undo 版本链即可。

---

## 16. 普通 SELECT 和 `SELECT ... FOR UPDATE` 有什么区别？

### 普通 SELECT

在 InnoDB 的 RC、RR 等常见隔离级别下，普通 `SELECT` 通常属于一致性读，也就是快照读。

例如：

```sql
SELECT *
FROM article
WHERE id = 100;
```

它通常通过 MVCC 读取符合当前 Read View 的版本，不会因为另一个事务正在修改这条记录就一定被阻塞。

### `SELECT ... FOR UPDATE`

```sql
SELECT *
FROM article
WHERE id = 100
FOR UPDATE;
```

这是锁定读。

它要读取当前数据，并对扫描到的相关记录加锁，防止其他事务对这些记录进行冲突修改。

常见场景：

```text
先查询余额
再扣余额

先查询库存
再扣库存
```

如果业务必须保证“我读到的这份数据接下来不能被别人抢先改掉”，可能需要 `FOR UPDATE` 或者直接设计原子 UPDATE。

### 一个很重要的实践点

不要把所有并发问题都靠：

```sql
SELECT ... FOR UPDATE
```

解决。

很多场景可以把：

```text
先查
再判断
再改
```

改成带条件的原子更新：

```sql
UPDATE stock
SET count = count - 1
WHERE id = ?
  AND count > 0;
```

再根据受影响行数判断是否成功。

---

## 17. Record Lock、Gap Lock、Next-Key Lock 是什么？

### Record Lock

记录锁，锁住某个索引记录。

例如：

```sql
SELECT *
FROM article
WHERE id = 100
FOR UPDATE;
```

如果通过唯一主键精确命中，核心就是锁住对应索引记录。

### Gap Lock

间隙锁，锁的是索引记录之间的区间，而不是某条现有记录本身。

例如有索引值：

```text
10
20
30
```

可能存在区间：

```text
(10,20)
(20,30)
```

Gap Lock 可以阻止其他事务在对应间隙插入新记录。

### Next-Key Lock

可以粗略理解成：

```text
Record Lock + Gap Lock
```

它既覆盖索引记录，也覆盖相关间隙。

### 为什么需要间隙相关锁？

因为只锁已有记录，无法阻止另一个事务往查询范围里插入新行。

RR 下，InnoDB 在一些范围锁定读、UPDATE、DELETE 场景中使用 Next-Key Lock，有助于处理幻读问题。

### 注意

锁加在索引上。

SQL 是否有合适索引，会直接影响锁定范围。如果没有合适索引，可能扫描和锁住比预期更多的数据。

---

## 18. 为什么会发生死锁？

### 面试回答

死锁的本质是多个事务形成循环等待。

例如：

事务 A：

```text
先锁 id = 1
再等 id = 2
```

事务 B：

```text
先锁 id = 2
再等 id = 1
```

形成：

```text
A 等 B
↑   ↓
B 等 A
```

双方都无法继续。

### 常见原因

最典型的是多个业务路径访问资源顺序不一致。

例如：

```text
业务 1：先更新订单，再更新账户
业务 2：先更新账户，再更新订单
```

高并发下容易形成循环等待。

### 如何降低死锁概率

- 让不同业务按统一顺序访问资源。
- 缩短事务时间。
- 不要在事务中做大量慢 IO 或远程调用。
- 给查询条件建立合适索引，减少锁扫描范围。
- 一次锁定多条数据时，尽量按稳定顺序处理。
- 控制事务中涉及的数据量。

---

## 19. 遇到死锁怎么办？

### 面试回答

InnoDB 可以检测很多死锁，并选择一个事务作为 victim 回滚，让另一个事务继续执行。

业务代码要做好：

```text
事务回滚
+
有限次数重试
```

因为死锁不是一定能通过设计完全消灭，高并发系统里偶发死锁需要业务有容错能力。

### 排查步骤

第一步，先拿到死锁现场。

常见方式包括：

```sql
SHOW ENGINE INNODB STATUS;
```

查看最近一次死锁信息。

还可以结合 Performance Schema 中的锁等待信息，以及数据库日志。

然后分析：

```text
事务 A 持有哪些锁
事务 A 在等什么

事务 B 持有哪些锁
事务 B 在等什么
```

最后回到 SQL 和事务顺序。

### 不要怎么处理

不要简单粗暴把：

```text
锁等待超时调得特别大
```

当成解决方案。

超时只是让问题拖得更久。

---

## 20. SQL 很慢，你第一步做什么？

### 面试回答

我不会上来直接说“加索引”。

通常会按这个流程排查：

```text
1. 确认慢 SQL
2. 看 SQL、参数和数据量
3. 看执行计划
4. 看扫描行数和实际返回行数
5. 看索引是否合适
6. 看 JOIN、排序、分组、分页
7. 判断能否改写 SQL
8. 修改后重新测试
```

### 先确认是不是真的 SQL 慢

接口慢不一定是 SQL 慢。

可能是：

```text
网络
Redis
第三方接口
线程池排队
GC
锁竞争
一次请求调用太多 SQL
```

所以应该先通过日志、APM、慢查询日志等方式找到真正耗时部分。

### 然后做什么？

对目标 SQL：

```sql
EXPLAIN ...
```

必要时：

```sql
EXPLAIN ANALYZE ...
```

重点确认：

- 实际走了什么索引
- 扫描多少行
- JOIN 顺序
- 是否发生额外排序
- 是否用了临时表
- 估算与实际是否差很多

---

## 21. EXPLAIN 主要看哪些字段？

### 面试回答

常见字段至少要认识：

```text
type
possible_keys
key
key_len
ref
rows
filtered
Extra
```

### type

表示访问方式。

常见可以粗略记成：

```text
const
eq_ref
ref
range
index
ALL
```

通常越靠前扫描范围越小，但不能机械地说 `ALL` 就一定有问题。

小表全表扫描很可能比走索引更划算。

### possible_keys

优化器认为可能可以使用的索引。

### key

最终实际选择的索引。

这个比 `possible_keys` 更关键。

### key_len

实际使用索引键的长度，可以辅助判断联合索引用到了多少部分。

### rows

优化器估算需要读取的行数。

如果 rows 很大，而最终只返回几行，要重点关注。

### filtered

表示经过条件过滤后预计保留的比例，可以帮助判断过滤效果。

### Extra

经常能看到：

```text
Using index
Using index condition
Using where
Using filesort
Using temporary
```

它们能提示覆盖索引、索引条件下推、额外排序、临时表等信息。

### EXPLAIN ANALYZE

它比普通 EXPLAIN 更适合进一步验证，因为它会实际执行语句，可以看到真实耗时、实际行数、循环次数等信息。

---

## 22. `Using filesort` 是什么意思？一定很差吗？

### 面试回答

`Using filesort` 表示 MySQL 不能直接依赖当前访问路径中的索引顺序得到最终排序结果，需要额外执行排序过程。

例如：

```sql
SELECT *
FROM article
WHERE category_id = 1
ORDER BY create_time DESC;
```

如果只有：

```sql
INDEX(category_id)
```

找到 `category_id = 1` 后，结果还需要按 `create_time` 排序。

### filesort 不等于一定写磁盘

名字容易误导。

它表示使用 MySQL 的额外排序算法，不代表一定真的产生磁盘文件。数据量小的时候可以在内存完成。

### `Using filesort` 一定要消灭吗？

不是。

如果只排序几十行：

```text
额外排序成本非常小
```

为了消灭一个 `Using filesort` 建一个宽联合索引，可能得不偿失。

还是看：

```text
数据量
排序行数
查询频率
索引维护成本
```

---

## 23. `Using index` 是什么意思？

### 面试回答

在传统 EXPLAIN 的 Extra 中看到：

```text
Using index
```

通常表示查询可以仅通过索引拿到需要的数据，也就是使用了覆盖索引，不需要再读取完整数据行。

例如：

```sql
INDEX idx_user_status(user_id, status)
```

查询：

```sql
SELECT user_id, status
FROM article
WHERE user_id = 10;
```

所有需要的列都在索引里。

### 别和 `Using index condition` 混了

`Using index condition` 通常表示使用了 Index Condition Pushdown。

意思是部分过滤条件可以在索引层判断，从而减少不必要的回表。

它不等同于“覆盖索引”。

---

## 24. `COUNT(*)`、`COUNT(1)`、`COUNT(column)` 有什么区别？

### 面试回答

### `COUNT(*)`

统计满足条件的行数。

```sql
SELECT COUNT(*)
FROM article
WHERE deleted = 0;
```

### `COUNT(1)`

同样用于统计行数。

在现代 MySQL 中，不应该再机械背：

> `COUNT(1)` 一定比 `COUNT(*)` 快。

通常优化器会进行相应优化，两者性能差异不是日常调优重点。

### `COUNT(column)`

统计这一列不为 `NULL` 的行数。

假设：

```text
id | age
1  | 18
2  | NULL
3  | 20
```

那么：

```text
COUNT(*)   = 3
COUNT(age) = 2
```

### 项目联系

项目的统计 SQL 里还有：

```sql
COUNT(*)
SUM(...)
AVG(...)
```

比如评论数、点赞数、收藏数、阅读数等。

这些聚合函数一定要区分语义，不要为了“性能传说”随便互换。

---

## 25. `LEFT JOIN` 和 `INNER JOIN` 有什么区别？

### INNER JOIN

只有两边能够匹配的数据才保留。

```sql
SELECT a.id, a.title, u.user_name
FROM article a
INNER JOIN user_info u
    ON a.user_id = u.user_id;
```

如果某篇文章找不到作者信息，这篇文章也不会出现在结果里。

### LEFT JOIN

左表数据必须保留。

```sql
SELECT a.id, a.title, u.user_name
FROM article a
LEFT JOIN user_info u
    ON a.user_id = u.user_id;
```

即使没有匹配到 `user_info`：

```text
article 数据仍返回
u.user_name = NULL
```

### 项目联系

`tech-community` 的文章、评论后台查询中用了多处 LEFT JOIN。

比如评论列表会关联：

```text
comment
article
user_info
parent comment
top comment
```

这类查询使用 LEFT JOIN，往往是因为主评论记录本身需要保留，即使某些关联信息不存在。

### 高频追问：条件写 ON 还是 WHERE？

以 LEFT JOIN 为例：

```sql
LEFT JOIN user_info u
ON c.user_id = u.user_id
AND u.deleted = 0
```

表示：

> 只关联未删除用户，但左边 comment 仍然保留。

如果写成：

```sql
LEFT JOIN user_info u
ON c.user_id = u.user_id
WHERE u.deleted = 0
```

那么匹配不到用户时 `u.deleted` 是 NULL，会被 WHERE 过滤掉，可能把 LEFT JOIN 实际效果变得接近 INNER JOIN。

---

## 26. WHERE 和 HAVING 有什么区别？

### 面试回答

WHERE 主要在分组前过滤原始行。

HAVING 主要在 GROUP BY 和聚合之后过滤分组结果。

例如：

```sql
SELECT article_id, COUNT(*) AS cnt
FROM comment
WHERE deleted = 0
GROUP BY article_id
HAVING COUNT(*) >= 10;
```

执行逻辑可以粗略理解成：

```text
FROM / JOIN
 ↓
WHERE
 ↓
GROUP BY
 ↓
HAVING
 ↓
SELECT
 ↓
ORDER BY
 ↓
LIMIT
```

这里：

```sql
WHERE deleted = 0
```

先把删除评论去掉。

然后：

```sql
GROUP BY article_id
```

按文章分组。

最后：

```sql
HAVING COUNT(*) >= 10
```

只留下评论数不少于 10 的文章。

### 性能意识

能在 WHERE 阶段确定的过滤条件，通常应该尽量提前过滤，减少后续参与分组的数据量。

---

## 27. UNION 与 UNION ALL 的区别？

### 面试回答

`UNION` 会合并两个结果集，并执行去重。

```sql
SELECT user_id FROM article
UNION
SELECT user_id FROM comment;
```

`UNION ALL` 直接拼接结果，不做去重。

```sql
SELECT user_id FROM article
UNION ALL
SELECT user_id FROM comment;
```

### 性能区别

去重需要额外工作，所以不需要去重时：

```text
优先 UNION ALL
```

一般更合适。

### 不要机械选择

如果业务语义就是要唯一值，那 `UNION` 的去重是必要逻辑。

优化不能以改变业务结果为代价。

---

## 28. IN 和 EXISTS 谁快？

### 面试回答

不能简单回答：

```text
IN 一定快
```

或者：

```text
EXISTS 一定快
```

现代 MySQL 优化器可能对子查询做半连接、物化、重写等优化。

例如：

```sql
SELECT *
FROM article a
WHERE a.user_id IN (
    SELECT user_id
    FROM user_info
    WHERE company = 'A'
);
```

可以写成 EXISTS：

```sql
SELECT *
FROM article a
WHERE EXISTS (
    SELECT 1
    FROM user_info u
    WHERE u.user_id = a.user_id
      AND u.company = 'A'
);
```

最终谁快取决于：

```text
数据量
数据分布
索引
选择性
MySQL 版本
优化器生成的执行计划
```

### 面试中更成熟的回答

> 我不会凭语法形式判断 IN 或 EXISTS 谁一定更快。先保证语义正确，再通过 EXPLAIN / EXPLAIN ANALYZE 看优化器实际采用的执行策略。

---

## 29. 为什么索引不是越多越好？

### 面试回答

索引能提高很多读操作，但每个索引都有成本。

### 1. 占磁盘空间

每个 B+ 树都要保存自己的节点和索引记录。

### 2. 消耗 Buffer Pool

热点索引页也需要进入内存。

索引越多越宽，同样内存能缓存的有效数据越少。

### 3. 写操作要维护索引

执行：

```sql
INSERT
UPDATE
DELETE
```

不仅要修改数据，也可能要修改多个索引树。

索引越多，写入成本越高。

### 4. 可能增加优化器选择成本

多个高度相似的索引会让结构更复杂，而且可能存在大量冗余索引。

例如：

```text
INDEX(a)
INDEX(a,b)
INDEX(a,b,c)
```

第一个、第二个是否真的还需要，要结合具体查询判断。

### 5. 低选择性单列索引未必有价值

比如：

```text
deleted
status
gender
```

如果绝大多数行都是相同值，单独索引这些列通常选择性很差。

但是它们作为联合索引的一部分仍可能有价值。

---

## 30. 你的技术社区项目里具体有哪些 SQL 可以优化？

### 面试回答

我会从真实查询模式出发，而不是看到表就乱加索引。

目前项目中至少有三类很适合作为调优案例：

### 1. 评论列表分页

评论查询存在：

```sql
WHERE c.article_id = ?
  AND c.deleted = 0
ORDER BY c.create_time DESC, c.id DESC
LIMIT ?, ?;
```

当前表结构里主要有：

```text
idx_article_id(article_id)
idx_user_id(user_id)
```

如果某篇文章评论很多，只靠 `article_id` 找出大量记录后还要继续过滤和排序，可能产生额外成本。

可以评估更贴合查询模式的联合索引。

### 2. 用户收藏列表

项目有：

```sql
SELECT document_id
FROM user_foot
WHERE user_id = ?
  AND document_type = 1
  AND collection_stat = 1
ORDER BY update_time DESC
LIMIT ?, ?;
```

而现有核心唯一索引是：

```text
(user_id, document_id, document_type)
```

`document_id` 位于中间，但这条查询没有按 document_id 过滤，所以这个索引不能很好覆盖后续条件和排序。

适合重新评估联合索引顺序。

### 3. 文章关键词搜索

项目数据库兜底搜索存在：

```sql
LIKE '%keyword%'
```

覆盖标题、短标题、摘要甚至正文。

这种包含搜索不是普通 B+ 树索引擅长的场景。

项目已经有 Elasticsearch 搜索链路，所以更合理的职责划分是：

```text
MySQL
负责事务数据和精确查询

Elasticsearch
负责全文检索
```

后面三题把这三个例子单独展开。

---

# 项目 SQL 调优实战

## 31. 评论列表 SQL 怎么调优？

### 当前查询特点

项目 `CommentMapper.xml` 中评论列表的核心结构大致是：

```sql
SELECT ...
FROM comment c
LEFT JOIN article a
    ON c.article_id = a.id
LEFT JOIN user_info u
    ON c.user_id = u.user_id
LEFT JOIN comment pc
    ON c.parent_comment_id = pc.id
LEFT JOIN comment tc
    ON c.top_comment_id = tc.id
WHERE c.deleted = 0
  AND c.article_id = ?
ORDER BY c.create_time DESC, c.id DESC
LIMIT ?, ?;
```

`comment` 表当前至少有：

```text
PRIMARY KEY(id)
INDEX idx_article_id(article_id)
INDEX idx_user_id(user_id)
```

### 潜在问题

假设一篇热门文章有几十万条评论。

只通过：

```text
idx_article_id(article_id)
```

找到所有这篇文章的评论后，还需要：

```text
过滤 deleted
按 create_time DESC, id DESC 排序
再取一页
```

如果命中行很多，扫描和排序成本会上升。

### 候选优化

可以评估类似：

```sql
CREATE INDEX idx_comment_article_deleted_time_id
ON comment (
    article_id,
    deleted,
    create_time DESC,
    id DESC
);
```

为什么这样排？

查询条件是：

```text
article_id = ?
deleted = 0
```

都是等值条件，放在前面。

后面：

```text
ORDER BY create_time DESC, id DESC
```

和索引顺序保持一致，有机会直接利用索引顺序完成分页，减少额外排序。

### 为什么把 id 也放进去？

原 SQL 是：

```sql
ORDER BY create_time DESC, id DESC
```

同一时间可能有多条评论。

加入 `id` 可以提供稳定的第二排序键，也更适合后续做游标分页。

### 深分页怎么办？

如果：

```sql
LIMIT 100000, 20
```

即使索引不错，也要跳过前面大量索引记录。

如果业务允许，可以改成基于上一页最后一条数据的游标分页：

```sql
SELECT ...
FROM comment
WHERE article_id = ?
  AND deleted = 0
  AND (
      create_time < ?
      OR (create_time = ? AND id < ?)
  )
ORDER BY create_time DESC, id DESC
LIMIT 20;
```

这比很大的 offset 更适合高页码场景。

### 怎么证明优化有效？

不能只看“我建了联合索引”。

应该对优化前后分别运行：

```sql
EXPLAIN ANALYZE
SELECT ...;
```

重点比较：

```text
实际扫描行数
是否出现额外排序
实际耗时
loops
最终使用的索引
```

### 面试版总结

> 评论列表主要按照 article_id、deleted 过滤，再按 create_time 和 id 倒序分页。原来单列 article_id 索引只能帮助缩小文章范围，如果单篇评论量很大，后续过滤和排序仍然有成本。我会根据实际数据量评估 `(article_id, deleted, create_time, id)` 这类联合索引，并用 EXPLAIN ANALYZE 验证。如果出现深分页，再考虑 keyset pagination，而不是只做 offset 分页。

---

## 32. 用户收藏列表 SQL 怎么调优？

### 项目原查询

`UserFootMapper.xml` 中有：

```sql
SELECT document_id
FROM user_foot
WHERE user_id = ?
  AND document_type = 1
  AND collection_stat = 1
ORDER BY update_time DESC
LIMIT ?, ?;
```

当前表里有一个很重要的唯一索引：

```text
(user_id, document_id, document_type)
```

还有：

```text
(document_id)
```

### 为什么现有联合索引不完全适合？

索引顺序是：

```text
user_id
 ↓
document_id
 ↓
document_type
```

查询条件是：

```text
user_id
document_type
collection_stat
```

并没有：

```text
document_id = ?
```

所以使用 `(user_id, document_id, document_type)` 时：

1. 可以先根据 `user_id` 缩小范围。
2. 第二列 `document_id` 没有条件。
3. 后面的 `document_type` 很难继续作为常规最左前缀定位条件。
4. `collection_stat` 根本不在索引中。
5. `update_time` 也不在索引中，所以排序还要额外处理。

### 候选索引

如果“用户收藏列表”是高频查询，可以评估：

```sql
CREATE INDEX idx_user_collection_list
ON user_foot (
    user_id,
    document_type,
    collection_stat,
    update_time DESC,
    document_id
);
```

### 为什么这样设计？

前三列：

```text
user_id
document_type
collection_stat
```

都是等值过滤。

接下来：

```text
update_time DESC
```

对应排序。

最后：

```text
document_id
```

是 SELECT 返回的字段，把它也放进索引后，有机会形成覆盖索引：

```sql
SELECT document_id
```

不需要回表。

### 这是一定要加的索引吗？

不是。

必须先看：

```text
user_foot 总数据量
每个用户平均足迹数
收藏查询 QPS
现有 SQL 实际耗时
新索引的写入成本
```

`user_foot` 本身是高频更新表，点赞、收藏、阅读、评论行为都可能修改它。

增加一个宽联合索引会增加：

```text
INSERT/UPDATE 成本
索引空间
Buffer Pool 压力
```

所以这是“候选索引”，不是看到 SQL 就无脑添加。

### 面试版总结

> 这条收藏 SQL 和原有 `(user_id, document_id, document_type)` 唯一索引的列顺序并不完全匹配。因为 document_id 位于中间但查询没有限制它，后面的 document_type 不能很好地继续缩小索引查找范围，同时 collection_stat 和 update_time 也不在索引里。如果收藏列表数据量和 QPS 都比较高，我会评估 `(user_id, document_type, collection_stat, update_time, document_id)`，既匹配等值过滤和排序，也可能覆盖 document_id。但 user_foot 是高频写表，所以最终要结合 EXPLAIN ANALYZE 和写入成本决定。

---

## 33. 为什么文章搜索里的 `LIKE '%keyword%'` 应该交给 Elasticsearch？

### 项目 SQL

项目文章搜索兜底查询包含类似：

```sql
WHERE a.deleted = 0
  AND (
      a.title LIKE CONCAT('%', ?, '%')
      OR a.short_title LIKE CONCAT('%', ?, '%')
      OR a.summary LIKE CONCAT('%', ?, '%')
      OR ad.content LIKE CONCAT('%', ?, '%')
  )
ORDER BY a.update_time DESC, a.id DESC
LIMIT ?;
```

其中正文还来自 `article_detail` 的最新版本子查询。

### MySQL 为什么不适合做这种全文包含搜索？

普通 B+ 树索引擅长：

```text
精确匹配
前缀匹配
范围查询
排序
```

但：

```sql
LIKE '%keyword%'
```

前面有 `%`，无法根据左侧前缀直接定位 B+ 树中的连续范围。

如果同时对多个字段做：

```text
title
short_title
summary
content
```

OR 查询，扫描成本会进一步增加。

正文还是 `LONGTEXT`，数据量上来以后更明显。

### MySQL FULLTEXT 能不能做？

可以讨论。

MySQL 有全文索引能力，但技术社区这种搜索通常还会需要：

```text
中文分词
多字段权重
相关性评分
高亮
复杂查询
搜索结果排序
后续扩展
```

如果项目已经使用 Elasticsearch，这些能力更适合集中交给 ES。

### 为什么不能完全只用 ES？

MySQL 仍然是业务事实数据源。

Elasticsearch 通常更适合：

```text
搜索索引
```

而不是替代事务数据库。

所以比较合理的职责是：

```text
MySQL
保存文章、作者、状态、正文等权威业务数据

       ↓ 数据同步

Elasticsearch
保存面向搜索的文档

       ↓

用户关键词检索
```

### 数据一致性怎么办？

这是继续追问时要会的。

MySQL 和 Elasticsearch 是两个系统，不可能靠一个普通本地事务把它们天然绑定成完全一致。

常见做法是：

```text
MySQL 先成功提交
↓
事务提交后发布事件 / MQ / CDC
↓
异步更新 ES
↓
失败重试
```

项目本身也有事务提交后回调工具：

```text
TransactionUtil.registryAfterCommitOrImmediatelyRun(...)
```

这类机制的思路就是：

> 数据库事务都没有成功提交时，不要提前执行某些外部副作用。

如果搜索索引允许短暂延迟，那么最终一致通常是更合理的方案。

### MySQL 兜底搜索还有没有价值？

有。

比如：

```text
ES 暂时不可用
数据量较小
后台简单查询
开发环境
索引重建期间
```

可以保留数据库兜底。

但要明确它的边界：

> `LIKE '%keyword%'` 是兜底方案，不是大规模全文检索的主要实现。

### 面试版总结

> 项目的文章搜索包含 title、short_title、summary 和正文的 `%keyword%` 包含查询，这种查询不能很好利用普通 B+ 树的前缀有序特性，数据量大以后扫描成本会明显上升。因此 MySQL 更适合继续作为事务数据源，全文检索交给 Elasticsearch 的倒排索引。MySQL 可以保留低数据量或故障场景下的兜底搜索。MySQL 和 ES 之间需要通过提交后事件、消息队列或 CDC 等方式做最终一致，而不是在数据库事务还没提交时就直接更新 ES。

---

# 面试前速记

## SQL 执行逻辑顺序

粗略记：

```text
FROM / JOIN
↓
WHERE
↓
GROUP BY
↓
HAVING
↓
SELECT
↓
ORDER BY
↓
LIMIT
```

---

## 联合索引

索引：

```text
(a, b, c)
```

优先理解成：

```text
先按 a 排
a 相同再按 b 排
b 相同再按 c 排
```

不是背一句“最左匹配”就结束。

---

## MVCC

记住这条链：

```text
当前记录
↓
事务版本信息
↓
Read View 判断
↓
不可见
↓
Undo Log 找旧版本
```

---

## SQL 调优

固定流程：

```text
找到慢 SQL
↓
确认真实参数和数据量
↓
EXPLAIN / EXPLAIN ANALYZE
↓
看扫描行数、索引、排序、JOIN
↓
设计候选优化
↓
重新验证
```

不要一上来就说：

```text
加索引
```

---

## 项目里最值得记住的三个调优案例

```text
CommentMapper
article_id + deleted + create_time/id
评论分页和深分页
```

```text
UserFootMapper
user_id + document_type + collection_stat + update_time
收藏列表联合索引与覆盖索引
```

```text
ArticleMapper
LIKE '%keyword%'
普通 B+ 树全文包含搜索的局限
MySQL 与 Elasticsearch 的职责划分
```
