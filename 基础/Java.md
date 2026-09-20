# 1. Java中基础的8种数据类型

byte, short, int, long
float, double
char, boolean

# 2. 集合类型

## 1. Collection

### 1. List

- ArrayList
- LinkedList
- Vector：线程安全，但性能不行，现在不用了

### 2. Set

- HashSet：最常见，元素无序，底层HashMap
- LinkedHashSet：有序
- TreeSet：自然排序

## 2. Map

- HashMap：最常见，无序，线程不安全
- LinkedHashMap：有序
- TreeMap：按键排序
- HashTable：线程安全，过时
- ConcurrentHashMap：并发安全首选