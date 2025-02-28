/**
 * Simple stopwatch timer implementation for D (-betterC, @nogc)
 *
 *  Copyright (c) 2025, Alexander Chepkov
 *
 *  License:
 *    $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 */

module nogcsw;

struct StopWatch {
@nogc nothrow:
private align(8):
    bool started;
    timeval timeStart, timeEnd;
    long timeMeasured;

    version (Windows) {
        struct timeval {
            long tv_sec;
            long tv_usec;
        }

        extern (C) int gettimeofday(timeval* tp, void* tzp) @nogc nothrow {
            import core.sys.windows.winbase : FILETIME, SYSTEMTIME, GetSystemTime, SystemTimeToFileTime;

            /**
             * Authors of this code snippet: Edouard Griffiths / ra1nb0w
             * @ https://github.com/f4exb/sdrangel/blob/master/custom/windows/windows_time.h
             * This magic number is the number of 100 nanosecond intervals since January 1, 1601 (UTC)
             * until 00:00:00 January 1, 1970
             */
            static const ulong EPOCH = 116_444_736_000_000_000UL;

            SYSTEMTIME system_time;
            FILETIME file_time;

            GetSystemTime(&system_time);
            SystemTimeToFileTime(&system_time, &file_time);

            ulong time = cast(ulong)file_time.dwLowDateTime;
            time += cast(ulong)file_time.dwHighDateTime << 32;

            tp.tv_sec = cast(long)((time - EPOCH) / 10_000_000L);
            tp.tv_usec = cast(long)(system_time.wMilliseconds * 1_000);

            return 0;
        }
    }

    version (Posix) import core.sys.posix.sys.time : timeval, gettimeofday;

public:
    this(bool autostart) {
        if (autostart)
            this.start();
    }

    void start() {
        this.started = true;
        gettimeofday(&this.timeStart, null), this.timeEnd = this.timeStart;
        this.timeMeasured = 0;
    }

    void stop() {
        if (this.started)
            this.elapsed(), this.started = false;
    }

    void restart() {
        this.stop(), this.start();
    }

    @property bool running() pure =>
        this.started;

    @property ulong elapsed() {
        if (this.started) {
            gettimeofday(&this.timeEnd, null),
            this.timeMeasured =
                (this.timeEnd.tv_sec - this.timeStart.tv_sec) * 1_000_000 + (
                    this.timeEnd.tv_usec - this.timeStart.tv_usec);
        }
        return this.timeMeasured;
    }

    @property long elapsed(string op)()
            if (op == "usecs" || op == "msecs" || op == "seconds") {
        static if (op == "usecs")
            return this.elapsed();
        static if (op == "msecs")
            return this.elapsed() / 1_000;
        static if (op == "seconds")
            return this.elapsed() / 1_000_000;
    }

    alias useconds_t = uint;

    void sleep(useconds_t usecs) {
        version (Windows) {
            import core.sys.windows.windows : Sleep;

            Sleep(usecs / 1_000);
        }
        version (Posix) {
            import core.sys.posix.unistd : usleep;

            usleep(usecs);
        }
    }

    void sleep(string op)(uint value)
            if (op == "usecs" || op == "msecs" || op == "seconds") {
        static if (op == "usecs") {
            version (Windows)
                assert(0, "Windows API does not support sleep in usecs");
            version (Posix)
                return this.sleep(value);
        }
        static if (op == "msecs")
            return this.sleep(value * 1_000);
        static if (op == "seconds")
            return this.sleep(value * 1_000_000);
    }
}

@nogc nothrow unittest {
    import core.stdc.stdio : printf;

    {
        auto sw = StopWatch(false);
        assert(sw.elapsed!"usecs" == 0);
        sw.start();

        sw.sleep!"seconds"(1);
        assert(sw.elapsed!"seconds" == 1);
        sw.stop();

        printf("#1: Elapsed time: %lu usecs\n", sw.elapsed!"usecs");
    }

    version (Posix) {
        {
            auto sw = StopWatch(true);

            sw.sleep!"usecs"(10);
            assert(sw.elapsed!"usecs" >= 10);
            sw.stop();

            printf("#2: Elapsed time: %lu usecs\n", sw.elapsed!"usecs");
        }
    }

    {
        auto sw = StopWatch(true);

        sw.sleep!"msecs"(2);
        assert(sw.elapsed!"msecs" == 2);
        assert(sw.running() == true);
        sw.stop();

        printf("#3: Elapsed time: %lu usecs\n", sw.elapsed!"usecs");
    }
}
