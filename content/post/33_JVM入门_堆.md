---
title: "JVM入门-堆"
date: 2021-01-27
draft: false
author: "小拳头"
categories: ["学习笔记"]
tags: ["JVM"]
---

上一篇笔记讲的是运行时方法区的线程独享的部分, 接下来将线程共享的方法区与堆.
![](/33_1.png)

## Heap(堆)
Java堆区在JVM启动的时候即被创建, 其空间大小也就确定了, 它是JVM管理的最大一块内存空间(堆内存的大小是可调). 堆在物理上不连续的内存空间中, 但在逻辑上它应该被视为连续. 堆空间逻辑上细分为: 新生区+养老区+永久代(JDK7); 新生区+养老区+元空间(JDK8). JDK7的如下
![](/33_3.png)

JDK8的如下
![](/33_33.png)

可以通过"-Xmx"和"-Xms"来设置堆用的内存, "-Xms"用于表示堆(年轻代+老年代)的**起始内存**; "-Xmx"用于设置堆的**最大内存**, 最好设置相同的值.

从实际使用的角度看, 几乎所有的对象的实例都在堆空间分配内存(可能存储在栈上). 数组或对象永远不会存储在栈上, 因为栈帧中只保存引用, 这个引用指向对象或者数组在堆中的位置. 在方法结束后, 堆中的对象不会马上被移除, 仅在垃圾收集的时候才会被移除.
![](/33_2.png)

查看堆内存代码: 
```
public class HeapSpaceInitial {
    public static void main(String[] args) {

        //返回Java虚拟机中的堆内存总量
        long initialMemory = Runtime.getRuntime().totalMemory() / 1024 / 1024;
        //返回Java虚拟机试图使用的最大堆内存量
        long maxMemory = Runtime.getRuntime().maxMemory() / 1024 / 1024;

        System.out.println("-Xms : " + initialMemory + "M");//-Xms : 245M
        System.out.println("-Xmx : " + maxMemory + "M");//-Xmx : 3641M

        System.out.println("系统内存大小为：" + initialMemory * 64.0 / 1024 + "G");//系统内存大小为：15.3125G; 物理电脑内存 / 64 = 初始内存
        System.out.println("系统内存大小为：" + maxMemory * 4.0 / 1024 + "G");//系统内存大小为: 14.22265625G; 物理电脑内存 / 4 = 最大内存

        try {
            Thread.sleep(1000000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

## OOM
OutOfMemory的产生主要就是因为不断地实例挤爆了堆空间.
```
public class OOMTest {
    public static void main(String[] args) {
        ArrayList<Picture> list = new ArrayList<>();
        while(true){
            try {
                Thread.sleep(20);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            list.add(new Picture(new Random().nextInt(1024 * 1024)));
        }
    }
}

class Picture{
    private byte[] pixels;

    public Picture(int length) {
        this.pixels = new byte[length];
    }
}
```

## 新生代老年代结构
存储在JVM中的java对象有生命周期较短的瞬时对象和生命周期非常长的对象. 几乎所有的Java对象都是在Eden区new出来的, 绝大部分新生代对象生命周期都很短. 而新生代老年代主要结构如下.
![](/33_4.png)

可以通过NewRatio=2(默认2)控制新生代老年代比例, 表示新生代占1, 老年代占2, 新生代占整个堆的1/3; Eden空间和另外两个Survivor空间缺省所占的比例是8:1:1, 可以通过-XX:SurvivorRatio=8(默认8)调整空间比例, 选项-Xmn设置新生代最大内存大小.

## 对象分配过程
一般的(针对幸存者s0, s1区: 复制之后有交换，谁空谁是to):

1. new的对象先放伊甸园区, 此区有大小限制.
2. Eden的空间填满时, 程序又需要创建对象, JVM的垃圾回收器将对Eden进行垃圾回收(Minor GC), 将伊甸园区中的不再被其他对象所引用的对象进行销毁, 再加载新的对象放到Eden区.
3. 将Eden中的剩余对象移动到幸存者0区.
4. 如果再次触发垃圾回收，此时上次幸存下来的放到幸存者0区的, 如果没有回收, 就会放到幸存者1区.
5. 如果再次经历垃圾回收，此时会重新放回幸存者0区，接着再去幸存者1区.
6. 进入老年区的阈值为15. 可以根据-XX:MaxTenuringThreshold=15设置。
7. 当老年区内存不足时，再次触发GC(Major GC), 进行老年区的内存清理. 若养老区执行了Major GC之后发现依然无法进行对象的保存，就会产生OOM异常.

下图包括了一般情况和特殊情况.
![](/33_5.png)

## 几种垃圾回收
**部分收集**: 不是完整收集整个Java堆的垃圾收集, 其中分为: 

1. 新生代收集(**Minor GC**/Young GC): 只是新生代的垃圾收集.
2. 老年代收集(**Major GC**/Old GC): 只是老年代的垃圾收集. 目前, 只有CMS GC会有单独收集老年代的行为. 很多时候Major GC会和Full GC混淆使用, 需要具体分辨是老年代回收还是整堆回收. 
3. 混合收集(Mixed GC): 收集整个新生代以及部分老年代的垃圾收集.

**整堆收集(Full GC)**, 收集整个java堆和方法区的垃圾. 

**新生代GC触发机制**: 当年轻代空间不足时, 就会触发Minor GC, 这里年轻代满是指Eden满，而Survivor满不会引发GC. (每次Minor GC会清理年轻代的内存，Survivor是被动GC，不会主动GC).

**老年代GC触发机制**: 指发生在老年代的GC, 出现了Major GC, 经常会伴随至少一次的Minor GC. Major GC速度一般会比Minor GC慢10倍以上, STW(Stop the World)时间更长.

**Full GC触发机制**: 调用System.gc()时, 系统建议执行Full GC, 但是不必然执行; 老年代空间不足; 方法区空间不足; 通过Minor GC后进入老年代的平均大小小于老年代的可用内存; 由Eden区, Survivor S0(from)区向S1(to)区复制时, 对象大小由于To Space可用内存, 则把该对象转存到老年代, 但老年代也位置不够. 

那么为什么要分代呢, 因为每一个对象的声明周期不同, 分代就可以优化GC性能. 

## 内存分配策略(对象提升规则)
1. 优先分配到Eden
2. 大对象直接分配到老年代, 所以我们写程序也要避免大对象
3. 长期存活的对象分配到老年代
4. 动态对象年龄判断: 如果Survivor区中相同年龄的所有对象大小的总和大于Survivor空间的一半, 年龄大于或等于该年龄的对象可以直接进入到老年代. 无需等到MaxTenuringThreshold阈值.
5. 空间分配担保, survivor中放不下的放在老年代.

## TLAB(为堆空间分配内存)
因为堆区是共享的, 所以线程不安全, 但是通过加锁又会影响效率, 所以需要**TLAB(Thread Local Allocation Buffers)**. 也就是**对Eden区域继续进行划分, JVM为每个线程分配了一个私有缓存区域.** 一旦对象在TLAB空间分配内存失败, JVM就会尝试着通过加锁机制确保数据操作的原子性, 直接在Eden空间中分配了内存.
![](/33_6.png)

## 堆的一些参数
1. -XX:PrintFlagsInitial: 查看所有参数的默认初始值
2. -XX:PrintFlagsFinal: 查看所有的参数的最终值(可能会存在修改，不再是初始值)
具体查看某个参数的指令: jps(查看当前运行中的进程); jinfo -flag SurvivorRatio 进程id(查看新生代中Eden和S0/S1空间的比例)
3. -Xms: 初始堆空间内存（默认为物理内存的1/64）
4. -Xmx: 最大堆空间内存（默认为物理内存的1/4）
5. -Xmn: 设置新生代大小（初始值及最大值）
6. -XX:NewRatio: 配置新生代与老年代在堆结构的占比
7. -XX:SurvivorRatio: 设置新生代中Eden和S0/S1空间的比例
8. -XX:MaxTenuringThreshold: 设置新生代垃圾的最大年龄(默认15)
9. -XX:+PrintGCDetails: 输出详细的GC处理日志;打印gc简要信息: -XX:+PrintGC; -verbose:gc.
10. -XX:HandlePromotionFailure：是否设置空间分配担保

在发生Minor Gc之前, 虚拟机会检查老年代最大可用的连续空间是否大于新生代所有对象的总空间. 如果大于, 则此次Minor GC是安全的. 如果小于, 则虚拟机会查看-XX:HandlePromotionFailure设置值是否允许担保失败. 

如果HandlePromotionFailure=true(jdk7后默认为true), 那么会继续检查老年代最大可用连续空间是否大于历次晋升到老年代的对象的平均大小. (大于: 尝试进行一次Minor GC, 但这次Minor GC依然是有风险的; 小于: 进行一次Full GC).

## 逃逸分析
随着JIT编译期的发展与逃逸分析技术逐渐成熟, 所有的对象都分配到堆上也渐渐变得不那么绝对了. 如果经过逃逸分析(Escape Analysis)后发现, 一个对象并没有逃逸出方法的话, 那么就可能被优化成栈上分配. 通过栈上分配就可以降低GC的回收频率. 

当一个对象在方法中被定义后, 对象只在方法内部使用，则认为没有发生逃逸, 就可以放在栈上; 反之发生逃逸. 所以**能使用局部变量的时候, 就不要在方法外定义**.

### 栈上分配
通过开启关闭DoEscapeAnalysis来对比运行时间, 开启了逃逸分析后, 执行速度被大大地优化了. 而且不会发生GC.
```
/**
 * 栈上分配测试, 通过开启关闭DoEscapeAnalysis对比运行时间
 * -Xmx1G -Xms1G -XX:-DoEscapeAnalysis -XX:+PrintGCDetails
 */
public class StackAllocation {
    public static void main(String[] args) {
        long start = System.currentTimeMillis();
        for (int i = 0; i < 10000000; i++) {
            alloc();
        }
        // 查看执行时间
        long end = System.currentTimeMillis();
        System.out.println("花费的时间为： " + (end - start) + " ms");
        // 为了方便查看堆内存中对象个数，线程sleep
        try {
            Thread.sleep(1000000);
        } catch (InterruptedException e1) {
            e1.printStackTrace();
        }
    }
    private static void alloc() {
        User user = new User();//未发生逃逸
    }
    static class User {

    }
}
```

### 同步省略
在动态编译同步块的时候, JIT编译器可以借助逃逸分析来判断同步块所使用的锁对象是否只能够被一个线程访问而没有被发布到其他线程. 如果没有, JIT编译器在编译这个同步块的时候就会取消对这部分代码的同步.
```
public class SynchronizedTest {
    public void f1() {
        Object hollis = new Object();
        synchronized(hollis) {
            System.out.println(hollis);
        }
    }
    //f1()其实本来就没有同步效果, 因为每次都会new, 所以优化成f2
    public void f2() {
        Object hollis = new Object();
        System.out.println(hollis);
    }
}
```

### 标量替换
标量Scalar是指一个无法在分解成更小的数据的数据, Java中的原始数据类型就是标量. 还可以分解的数据叫聚合量, 比如对象. 如果一个对象不被外部访问, 经过JIT优化, 这个对象就可以被拆解成多个成员变量, 节约内存.
```
/**
 * 标量替换测试, 开启关闭EliminateAllocations对比
 *  -Xmx100m -Xms100m -XX:+DoEscapeAnalysis -XX:+PrintGC -XX:-EliminateAllocations
 */
public class ScalarReplace {
    public static class User {
        public int id;//标量
        public String name;//聚合量(分解为char)
    }

    public static void alloc() {
        User u = new User(); //未发生逃逸
        u.id = 5;
        u.name = "www.atguigu.com";
    }

    public static void main(String[] args) {
        long start = System.currentTimeMillis();
        for (int i = 0; i < 10000000; i++) {
            alloc();
        }
        long end = System.currentTimeMillis();
        System.out.println("花费的时间为： " + (end - start) + " ms");
    }
}
```

> **JDK8之后intern字符串缓存和静态变量并不是被转移到元数据区，而是直接在堆上分配**. 而且在HotSpot上没有在栈上分配不会逃逸的对象, 所以我们可以明确对象实例都分配到堆上. 前面的现象其实主要还是因为标量替换带来的加速. 并且只有在`-server`模式下才(默认)会启用逃逸分析. 