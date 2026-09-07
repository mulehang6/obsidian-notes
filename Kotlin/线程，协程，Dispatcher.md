# 1. 线程
并行是指在完全相同的时间(exact the same time)执行某些操作，而并发则是利用CPU空闲资源快速切换任务，效果上就是单核在“同一时间”执行了多个任务(单个CPU核心在一个时间点只能执行一个任务，只是现代CPU很快，感觉上就是无数任务同时进行)

# 2. 协程
## 遇到的问题
### 1. 协程不执行
```kotlin
package com.learn.kotlin.app  
  
import kotlinx.coroutines.CoroutineScope  
import kotlinx.coroutines.Dispatchers  
import kotlinx.coroutines.launch  
import java.time.LocalDateTime  
  
fun main() {  
    println("start: ${LocalDateTime.now()}")  
    CoroutineScope(Dispatchers.Default).launch {  
        println("suspend code started: ${LocalDateTime.now()}")  
        suspendCode()  
        println("suspend code finished: ${LocalDateTime.now()}")  
    }  
    println("end: ${LocalDateTime.now()}")  
}  
  
fun blockCode() {  
    (1..9999_9999).forEach { it * it }  
    println("block code finished: ${LocalDateTime.now()}")  
}  
  
suspend fun suspendCode() {  
    (1..9999_9999).forEach { it * it }  
    println("suspend code finished: ${LocalDateTime.now()}")  
}
```

执行时，输出如下：
```text
start: 2026-09-07T13:13:06.215327
end: 2026-09-07T13:13:21.013154800
```
可以看到并没有协程，原因如下：(来自DeepSeek)
`Dispatchers.Default` 的线程是 daemon 线程。 JVM 的退出规则是：所有非 daemon 线程结束时进程就终止。main 函数返回后，main 线程（唯一的非 daemon 线程）结束了，协程任务还排在线程池里根本没轮到执行——JVM 立刻关掉进程，任务被直接丢弃。所以 `suspend code started` 都来不及打印。

解决方案：
结构化并发的标准教学写法
`runBlocking`会阻塞main进程，直到其作用域内所有<mark style="background-color: #FF5582A6;">子协程</mark>都完成
```kotlin
fun main() = runBlocking { // runBlocking  
    println("start: ${LocalDateTime.now()}")  
    CoroutineScope(Dispatchers.Default).launch {  
        println("suspend code started: ${LocalDateTime.now()}")  
        suspendCode()  
        println("suspend code finished: ${LocalDateTime.now()}")  
    }  
    println("end: ${LocalDateTime.now()}")  
}
```

### 2. 协程输出不完整
```text
start: 2026-09-07T13:38:31.461594900
end: 2026-09-07T13:38:31.468176300
suspend code started: 2026-09-07T13:38:31.468176300
```
只输出started，未输出finished
解决方案：
```kotlin
fun main() = runBlocking {  
    println("start: ${LocalDateTime.now()}")  
    launch(Dispatchers.Default) {  
        println("suspend code started: ${LocalDateTime.now()}")  
        suspendCode()  
        println("suspend code finished: ${LocalDateTime.now()}")  
    }  
    println("end: ${LocalDateTime.now()}")  
}
```

野协程吗，那看样子确实很野了。🤣
![[野协程.png]]

原因：
`CoroutineScope` 创建的协程不属于 `runBlocking` 作用域，`runBlocking` 不等它。于是发生了一场竞速：
1. launch 提交任务 → Default 线程池的 worker（daemon 线程）抢在 main 结束前拾起任务 → 打印了 suspend code started；
2. 同时间 main 打印 end → runBlocking 块结束 → main 线程终止；
3. JVM 判定所有非 daemon 线程结束 → 立即关闭进程，正在算 2 秒循环的协程被直接掐死 → finished 永远不会打印。

# 3. Dispatcher(调度器)

| 名称      | Dispatchers.Default | Dispatchers.IO                              |
| ------- | ------------------- | ------------------------------------------- |
| 适用场景    | CPU 重载型工作，无空闲资源     | I/O操作，读写文件，网络请求等，CPU idle，此时即使增加性能也不会加快请求速度 |
| 分配到的线程数 | 取决于设备               | 至多64线程                                      |

# 总结

- 进程：主要解决资源隔离问题，一个进程通常有独立的地址空间，。线程是进程里的执行单元，同一进程的线程共享堆等资源，但每个线程有自己的栈和执行状态，所以线程之间通信方便，但也会产生线程安全问题
- 协程比线程更轻量，通常由语言运行时或者协程框架调度，而不是由操作系统直接调度。多个协程可以复用少量进程。协程遇到挂起操作时可以释放当前线程，让线程去执行其他协程，所以特别适合大量IO并发任务。
协程最终仍需要线程来执行，因此如果是CPU重载型工作或调用阻塞式API(如sleep)，依旧会被阻塞