---
title: "重读Java多线程"
date: 2024-03-03
draft: false
author: "小拳头"
categories: ["TECH"]
---

在上半年我完成了《Java并发编程的艺术》的学习, 尽管一直没有写博客总结. 在这篇文章中, 我将挑战用一篇文章横扫Java多线程中, 我们必须了解的基础知识. 然而, 需要强调的是, 理解基础原理只是解锁多线程编程的大门, 而实际编写代码时, 更需要结合具体场景避免陷阱. 基础知识为我们规避那些因对多线程理解不足而导致的代码问题提供了支持, 但优化代码的过程需要深入实际应用. 

## 多线程有什么用
多线程这个概念在接触操作系统的时候就会遇到, 让我们有能力使程序在同一时间执行多个任务, 从而节省整体任务的执行时间, 更高效地利用计算机的性能. 但某些情况多线程并发执行并不一定会显著提高执行效率:
1. 一个简单任务, 如果开多个线程执行, 效率会低于串行执行, 因为线程切换上下文会带来额外的消耗
2. 软硬件的资源限制. 带宽有限, 开再多的线程也无法使下载速度突破带宽的物理限制. 或者CPU利用率已经很高了, 开多线程反而会加重CPU的负载, 使任务执行更慢.

在开始学习Java多线程的原理之前, 我还想阐述一点: 这里的多线程都是针对JVM这个维度的, 而不是操作系统维度. 操作系统本身会有自己的线程/进程管理调度, 诸如时间片轮转/短作业优先, CPU也会有物理核心和逻辑核心. 而JVM屏蔽了这些细节, 我们要关心的主要还是Java自身的线程状态, 配置线程池时, 也不能仅仅根据机器的CPU核心数来设置, 需要实际测试不同线程池状态下的性能才是正解.


## Java的线程
### 创建线程
todo: 三种创建方式/区别的例程. 返回值. 线程的状态.

### 两种加锁方式
线程之间共享变量是一种非常常见的场景, 如果对共享变量值的一致性要求高, 换句话说: 无论对这个值如何被改动, 所有线程看到的这个值都应该是一样的. 那么, 就需要用到Java提供的两种加锁方式: `volatile`与`synchronized`.

todo: 先来看一段代码: 
```

```

todo: 共享变量读异常case: 用交替打印的面试题解释.

### volatile
如果一个字段被声明成volatile, Java线程内存模型(JMM)确保所有线程看到这个变量的值是一致的. todo: 文档链接

volatile加锁代码:
```

```

### synchronized例程
三种加锁位置:
1. 加在普通方法上, 锁是当前实例对象
2. 加在静态方法上, 锁是当前类的Class对象
3. 加在方法块上, 锁是ynchonized括号中配置的对象

todo: 文档链接


synchronized加锁代码:
```

```

## JMM
## JMM抽象结构
Java Memory Model是抽象的模型, 目的是描述Java中线程与内存之间的关系. 从图中可以看到, 每个线程有自己的本地内存, 不同线程之间通过主内存来进行通信.
[](/89_1.png)

### 重排序
重排序指某个动作的执行顺序被重新排列, 有三种类型:
1. 编译器重排序: 代码语句执行顺序重新排列
2. 指令重排序: CPU改变机器指令的执行顺序重新排列
3. 内存重排序: CPU加载和存储缓存的顺序重新排列

### happens-before
因为重排序, 我们很难分析各种动作实际执行的顺序, 这会对敲代码产生困扰. 然而在实际编程的时候, 我们甚至会忘记这些重排序的存在, 这是因为JMM提供了happens-before的保证, 也就是说: **在程序正确同步的情况下, 程序执行的结果不会被重排序改变.** 对单线程程序, 天然是正确同步的, 所以也不会被重排序影响.

### volatile内存语义
可见性, 内存原子性

### 锁内存语义
cas

### final内存语义

### 双重检查
延迟初始化, 节省性能 -> 单例模式

不同场景的解决方案.

## juc锁 

## juc容器框架: 阻塞队列-concurrent-hashmap/queue

## 轻量级-13个原子更新类



## executor
原理, 线程池, 参数详解  


## 锁
volatile
Java锁


## 参考
1. Java并发编程的艺术
2. [Java threads and number of cores](https://stackoverflow.com/questions/34689709/java-threads-and-number-of-cores)
3. [JSR-133:Java Memory Model and Thread Specification]()