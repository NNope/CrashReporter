# CrashReporter
在iOS下 crash的采集方式。

####本文整理下最近对于crash采集的总结，和踩过的坑。
###CrashReporter
首先，iOS有自己的CrashReporter机制。在真机上产生的crash，在一下两个地方可以找到：

*  Xcode－Window－Devices － View Device Logs中可以看到crash文件。这是我的截图：
![QQ20170125-0@2x.png](http://upload-images.jianshu.io/upload_images/810907-53a945816e07869b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
关于各个字段的含义，我搜集了相关博客的介绍，有不对的地方大家可以指出：

|字段|含义|
|---|---|
|Incident Identifier|当前crash的 id，可以区分不同的crash事件|
|CrashReporter Key|当前设备的id，可以判断crash在某一设备上出现的频率|
|Hardware Model|设备型号|
|Process|当前应用的名称，后面中括号中为当前的应用在系统中的进程id|
|Path|当前应用在设备中的路径|
| Identifier |bundle id|
| Version |应用版本号|
|Code Type|还不清楚|
|Date/Time|crash事件 时间(后面跟的应该是时区)|
|OS Version|当前系统版本|
|Exception Type|异常类型|
|Exception Codes|异常出错的代码（常见代码有以下几种)<br>0x8badf00d错误码：Watchdog超时，意为“ate bad food”。<br> 0xdeadfa11错误码：用户强制退出，意为“dead fall”。<br>0xbaaaaaad错误码：用户按住Home键和音量键，获取当前内存状态，不代表崩溃。<br>0xbad22222错误码：VoIP应用（因为太频繁？）被iOS干掉。<br>0xc00010ff错误码：因为太烫了被干掉，意为“cool off”。<br>0xdead10cc错误码：因为在后台时仍然占据系统资源（比如通讯录）被干掉，意为“dead lock”。|
|Triggered by Thread|在某一个线程出了问题导致crash，Thread 0  为主线程、其它的都为子线程|
|Last Exception Backtrace|最后异常回溯，一般根据这个代码就能找到crash的具体问题|


*  通过iTunes Connect（Manage Your Applications - View Details - Crash Reports）获取用户的crash日志。需要用户在设置-诊断与用量中允许将崩溃信息发送给开发者。然后在也可以在Xcode的Window - Organizer中可以看到对应的crash信息。（需要在Xcode中登录所属的开发者账号）
![QQ20170125-1@2x.png](http://upload-images.jianshu.io/upload_images/810907-d0a9763e33a51e25.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

###.dSYM文件
取到的crash文件在崩溃信息会是地址信息，这时候需要使用打包时对应的dSYM文件进行符号表的解析工作，所以每次生产版本打包时，都需要保存对应的dSYM文件，一些第三方的crash采集分析平台也会要求上传对应的dSYM文件。
解析需要用到Xcode中一个symbolicatecrash的程序。目录地址在

`/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash
`
如果嫌麻烦，也可以直接输入命令
`find /Applications/Xcode.app -name symbolicatecrash -type f
`
将symbolicatecrash拷贝到crash文件，dSYM文件相同的目录中。

进入所在目录
`
cd /Users/username/Desktop/CrashReport
`
依次执行以下的命令即可输出为目标文件symbol.crash

```
export DEVELOPER_DIR=/Applications/XCode.app/Contents/Developer
./symbolicatecrash ./*.crash ./*.app.dSYM > symbol.crash
```


####以上这种获取crash信息的方式不够满足我们产品的需要，想通过用户主动上传或者同意发送崩溃信息存在太多的困难。


##依靠程序实现crash的捕捉
在搜索相关资料的时候，比较常见的方式分两种。

####异常处理机制 
同时对于系统Crash而引起的程序异常退出，可以通过`UncaughtExceptionHandler`机制捕获；

也就是说在程序中catch以外的内容，被系统自带的错误处理而捕获。我们要做的就是用自定义的函数替代该ExceptionHandler即可。
这里主要有两个函数

```
NSGetUncaughtExceptionHandler() 得到现在系统自带处理Handler；得到它后，如果程序正常退出时用来回复系统原先设置
NSSetUncaughtExceptionHandler() 红色设置自定义的函数
```
该方式可以捕捉到常见的数组越界等OC层面抛出的异常。
PS：在设置handler时需要注意一点。在念茜的[《漫谈iOS Crash收集框架》](http://www.cocoachina.com/ios/20150701/12301.html)中提到
> 如果同时有多方通过NSSetUncaughtExceptionHandler注册异常处理程序，和平的作法是：后注册者通过NSGetUncaughtExceptionHandler将先前别人注册的handler取出并备份，在自己handler处理完后自觉把别人的handler注册回去，规规矩矩的传递。不传递强行覆盖的后果是，在其之前注册过的日志收集服务写出的Crash日志就会因为取不到NSException而丢失Last Exception Backtrace等信息。（P.S. iOS系统自带的Crash Reporter不受影响）

建议在自己的handle处理完之后，设置回原先保存的别人注册的handler

####处理signal
除了OC层面的异常捕捉之外，很多内存错误、访问错误的地址产生的crash则需要利用unix标准的signal机制，注册SIGABRT, SIGBUS, SIGSEGV等信号发生时的处理函数。该函数中我们可以输出栈信息，版本信息等其他一切我们所想要的。

实例代码：

```objc
void SignalExceptionHandler(int signal)
{
    NSMutableString *mstr = [[NSMutableString alloc] init];
    
    [mstr appendString:@"Stack:\n"];
    
    void* callstack[128];
    
    int i, frames = backtrace(callstack, 128);
    
    char** strs = backtrace_symbols(callstack, frames);
    
    for (i = 0; i<frames;i++)
    {
         [mstr appendFormat:@"%s\n", strs[i]];
         
    }   //[ saveCreash:mstr];
}
void InstallSignalHandler(void)
{
    signal(SIGHUP, SignalExceptionHandler);
    signal(SIGINT, SignalExceptionHandler);
    signal(SIGQUIT, SignalExceptionHandler);
    signal(SIGABRT, SignalExceptionHandler);
    signal(SIGILL, SignalExceptionHandler);
    signal(SIGSEGV, SignalExceptionHandler);
    signal(SIGFPE, SignalExceptionHandler);
    signal(SIGBUS, SignalExceptionHandler);
    signal(SIGPIPE, SignalExceptionHandler);
}
```
关于这块，虽说能找到很多类似的、相互转载的资料，但是大部分的代码都多多少少有问题，没有奏效。[放个最后找到的可以用的地址](https://github.com/xcysuccess/iOSCrashUncaught)。
关于上述提到的多方通过NSSetUncaughtExceptionHandler注册异常时候的处理，所以我把这步优化加上了。[我的demo](https://github.com/NNope/CrashReporter)

**ps：关于signal信号的捕捉，在Xcode调试时，Debugger模式会先于我们的代码catch到所有的crash，所以需要直接从模拟器中进入程序才可以测试**


###相关开源库的实现
---
至此，简单的crash采集工作基本算是完成了，能一定程度上满足对于crash日志信息采集的需求了，也能从信息中定位到问题所在。

但是这种方式获取到的日志信息（指signal信号捕捉的信息）有简单的崩溃堆栈信息，不需要进行符号表的反解。
并且我查看了某个平台的crash文件格式，上文说到平台需要提前上传dSYM文件。文件格式和系统生成的crash文件基本一致，该有的字段信息都有。所以相关实现肯定是不一样的，在翻阅头文件的时候看到了`#import <mach/mach.h>`,回想起上文提到的念茜去年的一篇博客 -[《漫谈iOS Crash收集框架》](http://www.cocoachina.com/ios/20150701/12301.html)。之前看的时候，云里雾里，现在稍许有些概念。

>所有Mach异常都在host层被ux_exception转换为相应的Unix信号，并通过threadsignal将信号投递到出错的线程。iOS中的 POSIX API 就是通过 Mach 之上的 BSD 层实现的。
>
>因此，EXC_BAD_ACCESS (SIGSEGV)表示的意思是：Mach层的EXC_BAD_ACCESS异常，在host层被转换成SIGSEGV信号投递到出错的线程。既然最终以信号的方式投递到出错的线程，那么就可以通过注册signalHandler来捕获信号:
>
`
signal(SIGSEGV,signalHandler);
`
>
捕获Mach异常或者Unix信号都可以抓到crash事件，这两种方式哪个更好呢？ 
>>优选Mach异常，因为Mach异常处理会先于Unix信号处理发生，如果Mach异常的handler让程序exit了，那么Unix信号就永远不会到达这个进程了。转换Unix信号是为了兼容更为流行的POSIX标准(SUS规范)，这样不必了解Mach内核也可以通过Unix信号的方式来兼容开发。


猜测就是通过mach的相关接口获取到崩溃信息的。于是去github上找了相关的开源**[KSCrash](https://github.com/kstenerud/KSCrash)**，**[plcrashreporter](https://github.com/plausiblelabs/plcrashreporter)**。确实这两个库中都得到了对应上述的crash文件中大部分的信息。于是开始着手**plcrashreporter**的集成使用。

---
###plcrashreporter
####集成
作者在工程里新建了多个target，对应模拟器的.a库、iOS的.a库、iOS的framework、Mac的framework等。对framework也做了模拟器和真机版本的合并操作。直接将对应的framework拖入到自己工程中使用就可以了。
相关的集成代码包括：

```objc
// 是的调试模式下是无法获取到crash信息的 作者直接让demo退出了
 if (debugger_should_exit()) {
        NSLog(@"The demo crash app should be run without a debugger present. Exiting ...");
        return 0;
    }
    
    /* Configure our reporter */
    PLCrashReporterConfig *config = [[[PLCrashReporterConfig alloc] initWithSignalHandlerType: PLCrashReporterSignalHandlerTypeMach
                                                                        symbolicationStrategy: PLCrashReporterSymbolicationStrategyAll] autorelease];
    PLCrashReporter *reporter = [[[PLCrashReporter alloc] initWithConfiguration: config] autorelease];

    /* Save any existing crash report. */
    // demo每次启动会把上次的crash日志拷贝到document目录下，并且开启了itunes的共享
    save_crash_report(reporter);
    
    /* Set up post-crash callbacks */
    PLCrashReporterCallbacks cb = {
        .version = 0,
        .context = (void *) 0xABABABAB,
        .handleSignal = post_crash_callback
    };
    [reporter setCrashCallbacks: &cb];

    /* Enable the crash reporter */
    // 开启crashrepoter
    if (![reporter enableCrashReporterAndReturnError: &error]) {
        NSLog(@"Could not enable crash reporter: %@", error);
    }

    /* Add another stack frame */
    // demo制造的一个crash
    stackFrame();

```
####解析
在沙盒的library-cache中保存了一个plcrash格式的文件，如何使用这个文件。作者提供了一个CrashViewer的Mac程序来打开。所以在集成后，可以自己添加plcrash的解析，写成log格式到本地，进行自己的上报操作。在工具中可以看到主要的解析代码是：

```objc
- (BOOL) readFromData: (NSData *)data ofType: (NSString *)typeName error: (__autoreleasing NSError **)outError
{
    if ([typeName isEqual: @"PLCrash"]) {
        PLCrashReport *report = [[PLCrashReport alloc] initWithData: data error: outError];
        if (!report)
            return NO;

        NSString *text = [PLCrashReportTextFormatter stringValueForCrashReport: report
                                                                withTextFormat: PLCrashReportTextFormatiOS];
        self.reportText = text;
        return YES;
    } else if ([typeName isEqual: @"com.apple.crashreport"] || [typeName isEqual: @"public.plain-text"]) {
        NSString *text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        self.reportText = text;
        return text != nil;
    }
    return NO;
}
```
我原本是想通过程序菜单栏中的![菜单栏](http://upload-images.jianshu.io/upload_images/810907-5eefcfdb15a836cd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
**刚说完立马醒悟了**

file按钮找到对应的处理函数，但是竟然找不到对应的按钮action。。有点僵硬，虽然最后是找到这个方法，但是也不知道怎么进来的，了解mac开发的同学可以指导我一下。

好吧我再去看了下， 这个应该是系统直接指定的，应该是固定的代理方法。

####上传
接下来按照我了解的某平台的做法，第一次使用plcrashreporter生成plcrash文件，在第二次启动的时候进行解析，然后写为log文件。再进行发送上报的操作。在log内部可以增加标识记录该log是否已上传。**另外已上传的可以考虑删除、当目录大小超过某个值的时候也可以做删除操作**。这些都是需要自己实现的。

在测试的时候还遇到一个问题
首先我们已经知道Xcode调试模式下无法获取到crash日志，但是作者在框架内部做了控制，xcode的运行直接崩溃，我尝试通过作者demo中利用`debugger_should_exit()`中类似的方式去修改源码所相关的地方，但还是不奏效。无奈之下只好暂时利用这个函数加以控制crashreporter的开关来保证Xcode的正常调试.

---
###KSCrash
根据github上的commit记录来看，这个库的维护频率要比plcrashreporter高很多，并且有比较详细的README可以了解相关使用方式，大家可以优先了解这个库。之所以我先尝试plcrashreporter的集成是因为我看到某平台也是使用这种方案的，并且没有README的介绍，于是就先做下去了。KSCrash的介绍比较详细，后续会再进行对比。（简单的到了下demo，获取到的日志是一个json文件，并且格式与代码中拼接中的不一样，还没有进一步了解）。