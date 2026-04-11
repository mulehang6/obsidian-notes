# 1. Function Call和MCP的区别

Function Call的重点是让LLM生成结构化的函数调用参数，由业务代码去执行实际的功能，而MCP是模型和外部工具之间的通用协议，重点是把工具接入方式标准化

# 2. MCP的两种模式
- 1. stdio：更适合本地场景，一般是客户端本地直接拉起MCP服务，通过标准输入输出通信，链路短，实现简单，隔离性也比较好，官方文档称之为`Local MCP Server`，我经常用的context7和idea mcp都是这种
- 2. streamable http：更适合远程部署，因为server可以作为独立服务运行，能处理多个客户端的请求，也更方便接入网络服务、认证授权和统一部署


  