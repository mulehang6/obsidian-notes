# 1. 什么是Elasticsearch？

ES可以理解为一个偏搜索场景的数据库：数据存进去以后，按index/document/field的形式组织，类似于关系型数据库中的 表/行/列。核心优势是全文检索和关系性排序，ES官方定义：基于 Lucene 的分布式搜索与分析引擎

# 2. 几种不同的查询类型

# 1. bool查询

就是把多个条件组合起来，类似MySQL中的`and`关键字，但是他比SQL更细，因为ES还关心相关性评分。

```json
{
  "bool": {
    "must": [],
    "filter": [],
    "should": [],
    "must_not": []
  }
}
```

- must：必须满足，参与评分，适合全文检索条件
- filter：必须满足，不参与评分，适合放精确匹配条件，如：文章必须在线，必须属于某一个分类
- should：最好满足，满足了可以加分
- must_not：必须不满足

# 2. match

最常见的全文检索查询。先对用户的输入进行分析，再去匹配字段。根据官方文档，match是执行全文搜索的标准查询，例：
```json
{
  "match": {
    "title": "Java 并发编程"
  }
}
```

适合搜title，summary，content

# 3. multi_match

同时查询多个字段，基于match，例：
```json
{
  "multi_match": {
    "query": "Java 并发",
    "fields": ["title^3", "shortTitle^2", "summary", "content"]
  }
}
```

title^3, shortTitle^2 表示权重更高

# 4. term

精确查询，不分词，官方文档建议用于查找包含精确值的文档，如产品ID

# 5. terms

多个精确值查询，类似于SQL中的
```sql
where category_id in(1, 2, 3)
```

例如：
```json
{
  "terms": {
    "categoryId": [1, 2, 3]
  }
}
```

# 6. range

范围查询，例如：
```json
{
  "range": {
    "updateTime": {
      "gte": "2026-01-01",
      "lte": "2026-06-01"
    }
  }
}
```

# 7. exists

判断字段是否存在，比如：只查有封面图的文章，例如：
```json
{
  "exists": {
    "field": "picture"
  }
}
```

# 8. fuzzy

模糊匹配，适合处理轻微的拼写错误