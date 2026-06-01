# 1. 基础知识

## 1-1. 主从复制原理

MySQL的主从复制是基于binlog的，也就是记录MySQL所有的变化并以二进制形式保存到磁盘

主从复制就是将binlog中的数据从主库传输到从库上，一般这个过程是异步的。
[[MySQL主从复制流程]]

文字流程：
- 1. 主库写binlog：主库的更新(update，insert，delete)被写到binlog
- 2. 主库发送binlog：主库创建一个log dump线程来发送binlog给从库
- 3. 从库写relay log：从库在连接到主节点时会创建一个IO线程，以请求主库更新的binlog，并把接受的binlog信息写入一个叫做relay log的日志文件
- 4. 从库回放：从库还会创建一个SQL线程读取relay log中的内容，并且在从库中做回放，最终实现主从的一致性

## 1-2. canal基础

canal是一款常用的数据同步工具，其原理是基于binlog订阅的方式实现，模拟一个MySQL slave订阅binlog日志，从而实现CDC(change data capture)，并将已提交的更改发送给下游

流程：
- 1. canal服务端向MySQL的master节点传输dump协议
- 2. MySQL 的master节点接收到dump请求后推送binlog日志给canal服务端，解析binlog对象(原始为byte流)转换成JSON格式
- 3. canal客户端通过TCP协议或MQ形式监听canal服务端，同步数据到ES


# 2. 踩坑总结

- MySQL binlog文件名默认以设备名开头，我的是中文名，默认会乱码(主要是canal这边的问题)
- canal截至2026.6.1的最新版：1.1.8，依旧只能使用(或者说最好使用Java8来启动)
- 依旧忘记了es密码，又重置了一遍