
# 1. Spring 基础

## 5. Spring容器与Web容器的区别

从概念上来说，Spring容器是一个IoC容器，主要负责管理Java对象的生命周期和依赖关系。
而Web容器，例如Tomcat，是运行Web应用的容器，负责处理HTTP请求和响应，管理Servlet的声明周期

从功能上看，Spring容器专注于业务逻辑层面的对象管理，例如Controller，Service，dao等这些Bean都是由Spring容器来创建和管理的。
而Web容器专注于处理网络通信，比如接受HTTP请求，解析请求参数，响应客户端

在实际的业务中，这两个是相辅相成的。Web项目部署在Tomcat上的时候，Tomcat接收到请求，然后把请求交给`DispatcherServlet`处理，而`DispatcherServlet`又回去Spring容器中查找相应的Controller来处理业务逻辑。

还有一个重要的是生命周期。Web容器的生命周期跟Web应用的部署和卸载相关，而Spring容器的声明周期是包裹了Web容器的生命周期的，也就是说Web容器启动前，Spring容器就已经初始化了，而直到Web容器销毁，Spring容器才会销毁

现在我们都是用的Spring Boot，已经内置了Spring容器和Tomcat，只需要运行一个jar包就可以了

## 6. 你怎么理解Bean？

Bean本质上就是交由Spring容器管理的Java对象，但是跟Java对象不同的是，Bean并不是由程序员手动new出来，而是交由Spring容器管理他的整个生命周期。

从实际使用的角度来说，Controller，Service，dao等都是Bean，以`UserService`为例，使用`@Service`注解标记，就成了Bean，之后在需要使用的时候，Spring会自动创建它的实例。

### `@Component`和`@Bean`有什么区别

从使用上来说，`@Component`是标注在类上的，而`@Bean`则是标注在方法上的，`@Component`是告诉Spring这是个组件，把他注册成Bean，而`@Bean`则是告诉Spring将这个方法的返回对象注册成为Bean

从控制权角度来说，`@Component`是完全交由Spring控制的，而`@Bean`则是我们手动指定为Bean的，我们对他的创建过程有完全的控制权

## 7. Bean的生命周期

主要分为五个阶段：实例化、属性赋值、初始化、使用中、销毁。

- 实例化：Spring会根据BeanDefinition，通过反射调用构造方法来创建对象实例，如果有多个构造方法，那么则会根据注入的规则选择合适的构造方法。

- 属性赋值：包括通过`@Autowired`、`@Resource`这些注解注入的依赖对象，以及通过`@Value`注入的配置值

- 初始化：这个阶段会依次执行：
  - `@PostConstruct`标注的方法
  - `InitializingBean`接口的`afterPropertiesSet`方法
  - 通过`@Bean`的`initMethod`指定的初始化方法
  
  > 我在项目中经常用`@PostContruct`来执行一些初始化工作，例如缓存预加载，DB配置等
  
  ```java
// CategoryServiceImpl中的缓存初始化
@PostConstruct
public void init() {
    categoryCaches = CacheBuilder.newBuilder().maximumSize(300).build(new CacheLoader<Long, CategoryDTO>() {
        @Override
        public CategoryDTO load(@NotNull Long categoryId) throws Exception {
            CategoryDO category = categoryDao.getById(categoryId);
            // ...
        }
    });
}

// DynamicConfigContainer中的配置初始化
@PostConstruct
public void init() {
    cache = Maps.newHashMap();
    bindBeansFromLocalCache("dbConfig", cache);
}
  ```
  
  初始化后，Spring会调用所有注册的`BeanPostProcessor`后置处理方法。这个阶段常用来创建代理对象，例如AOP代理对象

- 使用阶段：
  ```java
// UserController中的使用示例
@Autowired
private UserService userService;
@GetMapping("/users/{id}")
public UserDTO getUser(@PathVariable Long id) {
    return userService.getUserById(id);
}
// UserService中的使用示例
@Autowired
private UserDao userDao;
public UserDTO getUserById(Long id) {
    return userDao.getById(id);
}
// UserDao中的使用示例
@Autowired
private JdbcTemplate jdbcTemplate;
public UserDTO getById(Long id) {
    String sql = "SELECT * FROM users WHERE id = ?";
    return jdbcTemplate.queryForObject(sql, new Object[]{id}, new UserRowMapper());
}
  ```
  
- 销毁阶段：当容器关闭或Bean被移除时，会依次执行：
  - `@PreDistroy`标注的方法
  - `DisposableBean`接口的`destroy`方法
  - 通过`@Bean`的`destroyMethod`指定的销毁方法
# 2. Spring AOP部分
## 1. 说说什么是AOP

### 非面经部分，帮助理解

AOP，也就是面向切面编程，就是把一些业务逻辑中相同的代码块抽到一个独立的模块中，让业务逻辑更加清爽。例如日志功能。
[[Excalidraw/AOP/Spring AOP.excalidraw.md#^FxbxD43N]]

例如有很多Service，每个Service都需要记录执行日志，检查权限，管理事务等。如果没有AOP，每个方法都需要写这样的代码：
```java
public void createUser(User user) {
    log.info("开始执行createUser方法");
    // 权限检查
    if (!hasPermission()) {
        throw new SecurityException("无权限");
    }
    // 开启事务
    transactionManager.begin();
    try {
        // 真正的业务逻辑
        userDao.save(user);
        transactionManager.commit();
        log.info("createUser方法执行成功");
    } catch (Exception e) {
        transactionManager.rollback();
        log.error("createUser方法执行失败", e);
        throw e;
    }
}
```

很明显，每个方法都这么写会很臃肿，AOP就是用来解决这个问题的，它可以把那些横切关注点(如日志，权限，事务等)从业务代码中抽取出来。

```java
@Aspect
@Component
public class LoggingAspect {
    @Before("execution(* com.example.service.*.*(..))")
    public void logBefore(JoinPoint joinPoint) {
        log.info("开始执行方法: " + joinPoint.getSignature().getName());
    }
    @AfterReturning("execution(* com.example.service.*.*(..))")
    public void logAfterReturning(JoinPoint joinPoint) {
        log.info("方法执行成功: " + joinPoint.getSignature().getName());
    }
    @AfterThrowing(pointcut = "execution(* com.example.service.*.*(..))",
                   throwing = "ex")
    public void logAfterThrowing(JoinPoint joinPoint, Throwable ex) {
        log.error("方法执行失败: " + joinPoint.getSignature().getName(), ex);
    }
}
```

然后，业务代码就很干净了：

```java
public void createUser(User user) {
    // 只需要关注业务逻辑，不需要关心日志、权限、事务等
    userDao.save(user);
}
```

### 面经部分

从技术实现上来说，AOP主要是通过动态代理来实现的。如果目标类实现了接口，就用JDK的动态代理；如果没有，就用CGLIB来创建子类代理。代理对象会在方法执行前后插入自定义的切面逻辑。

## 2. Spring AOP有哪些核心概念

- 1. 切面：自定义的切面类，使用`@Aspect`注解，包含要在什么时候、什么地方执行什么逻辑。比如定义一个日志切面，专门负责记录方法的执行情况。

- 2. 切点：定义在哪些地方应用切面逻辑。就是告诉Spring要在哪个方法上生效，可以写个切点表达式，用于匹配包名，让所有Service层都生效，也可以是某个包下的特定方法。使用`@Point`注解，通常会与一些形如`execution(com.example.service..*(..))`。

- 3. 通知：是切面中具体要执行的逻辑。有几种类型：
  - `@Before`：方法执行前
  - `@After`：方法执行后
  - `@Around`：环绕通知，可以在方法执行前后都执行
  - `@AfterReturning`：在方法正常返回执行结果后执行
  - `@AfterThrowing`：在方法抛异常后执行
  
  我一般使用`@Around`用的多，因为这个最灵活，可以控制方法是否执行，也可以修改参数和返回值

- 4. 连接点：被拦截到的点，因为Spring只支持方法类型的连接点，所以在Spring中，连接点指的就是被拦截到的方法，实际上连接点还可以是字段或者构造方法。

- 5. 织入：把切面逻辑应用到切点的过程。Spring AOP是在运行时通过动态代理来实现的，当我们从Spring容器中获取Bean的时候，如果这个Bean需要被切面处理，Spring就会返回一个代理对象给我们。

- 6. 目标对象：就是Controller，Service等具体的类。Spring  AOP会在目标对象上织入切面逻辑

关系大概是这样的：
```txt
切面(Aspect)
	|-> 切入点(Pointcut) 定义在哪里执行
	|-> 通知(Advice)    定义什么时候执行
		|-> @Before    目标执行前
		|-> @After     目标执行后
		|-> @Around    目标执行前后均可
		|-> @AfterReturning 目标正常返回后执行
		|-> @AfterThrowing  目标抛异常后执行
	
目标对象(Target) -> 代理对象(Proxy) -> 织入(weaving)
    ↑                                     ↓
连接点(join point)                      客户端调用
```
