---
title: "JVM入门-类加载子系统"
date: 2021-01-25
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["JVM"]
---

通过Class Loader SubSystem从文件系统或者网络中加载Class文件. ClassLoader只负责`XXX.class`文件的加载, 至于它是否可以运行, 则由Execution Engine决定. 加载的类信息存放在方法区`XXX.Class`. 通过调用`XXX.Class`的构造器就可以进行实例化.
![](/31_1.png)
![](/31_2.png)

## Loading
通过一个类的全限定明获取定义此类的二进制字节流, 将这个字节流所代表的的**静态存储结构转化为方法区的运行时数据**, 在内存中生成一个代表这个类的**java.lang.Class**对象, 作为方法区这个类的各种数据的访问入口.

## Linking
**Verify阶段**, 这个阶段去验证被加载的类是不是复合虚拟机要求的, 字节码开头是CA FE BA BY.

**Prepare阶段**为类的变量分配内存, 同时给这些变量进行初始化(0, false, null等等), 但是final修饰的static变量(常量)除外, 因为这些常量会在编译的时候就分配内存, 并在Prepare阶段显式初始化. 实例变量(方法中的对象)也不会被初始化, 而是随对象一起分配到堆中. 而方法变量会分配在方法区.

**Resolution阶段**将常量池内的符号引用转换为直接引用(以后讨论).

> 可以通过`javap -v XXX.class`反编译

## Initialization
- 初始化阶段就是执行类构造器方法`clinit()`的过程, 此方法不需要定义，是javac编译器自动收集类中的所有**类变量的赋值动作**和**静态代码块中**的语句合并而来. 这里注意类变量就是静态变量, 所以实际上可以理解为`clinit()`只和静态有关, 如果没有静态代码块, 没有类变量, 那么也就没有`clinit()`.
- 并且构造器方法中指令按语句在源文件中出现的顺序执行. 如下图
![](/31_3.png)
- clinit()不同于类的构造器, 构造器函数就是上图的init, 因为我们创建了类, 那构造器就一定被调用了, 所以始终可以看到`init`
- JVM保证子类clinit()执行前, 父类clinit()执行完毕; 一个类的clinit()在多线程下会被同步加锁.

> **static代码块**
> 
> 内部可以有输出语句; 随着类的加载而执行; 只执行一次; 初始化类信息; 多个静态代码块按声明顺序先后执行, 但是优先于非静态代码块; 只能调用静态结构, 因为还没对象的初始化
> 
> **非static代码块**
> 
> 内部可以有输出语句; 随着对象的创建而执行; 每创建一个对象, 执行一次非静代码块; 可以在创建对象时, 对象属性会被初始化

## ClassLoader
严格来说类加载器分为**Bootstrap Classloader**和**User-Defined ClassLoader**. 
![](/31_4.png)

概念上来说将所有派生于抽象类ClassLoader的类加载器都看做User-Defined ClassLoader.
![](/31_5.png)

演示如下
![](/31_6.png)

1. **Bootstrap Classloader**: 用C/C++实现的, 嵌套在JVM内部; 它用来加载java的核心库; 不继承自java.lang.ClassLoader, 没有父加载器; 加载拓展类和应用程序类加载器，并指定为他们的父加载器; 只加载包名为java、javax、sun等开头的类.
2. **Extension ClassLoader**: 由sun.misc.Launcher$ExtClassLoader实现, 派生于ClassLoader类, 父类加载器为Bootstrap Classloader(但获取不到); 从java.ext.dirs系统属性所指定的目录中加载类库，或从JDK的安装目录的jre/lib/ext子目录(扩展目录)下加载类库。如果用户创建的JAR放在此目录下，也会由拓展类加载器自动加载.
3. **AppClassLoader**: 由sun.misc.Launcher$AppClassLoader实现, 派生于ClassLoader类, 父类加载器为拓展类加载器, 它负责加载环境变量classpath或系统属性java.class.path指定路径下的类库. 是程序中默认的类加载器.

## 双亲委派机制
Java虚拟机对class文件采用的是按需加载的方式. 也就是说一个类加载的时候会先不断向上委派, 父类加载器不能加载了, 才会让子类加载器加载. 双亲委派机制避免了类的重复加载, 并且防止核心api被随意修改.
![](/31_7.png)

做一个实验. 这个实验中, 最后会由Bootstrap Classloader加载核心库的java.lang.String, 而核心库的`String`类是没有main方法的, 这也是**安全机制**的体现, 类加载器先加载了jdk自带的文件(rt.jar包中的java\lang\String.class). 
![](/31_8.png)

在jvm中表示两个class对象是否为同一个类存在的两个必要条件有两个: 1.类的(包含包名)完整类名必须一致; 2.**加载这个类的ClassLoader(指ClassLoader实例对象)必须相同**. 类的被动使用, 都不会导致类的初始化. 主动使用包括创建类的实例, 访问某各类或接口的静态变量，或者对静态变量赋值, 调用类的静态方法, 反射, 初始化一个类的子类等.