# nogcsw
Simple stopwatch timer implementation for D (-betterC, @nogc). Actually, this is a simplified betterC port of druntime/blob/master/src/rt/aaA.d

## Use below subconfiguration for betterC in your dub.json
```json
"subConfigurations": {
        "nogcsw": "nogc"
}
```

## Examples:
```d
    import core.stdc.stdio : printf;
    import nogcsw;

    {
        auto sw = StopWatch(false);
        assert(sw.elapsed!"usecs" == 0);
        sw.start();

        sw.sleep!"seconds"(1);
        assert(sw.elapsed!"seconds" == 1);

        sw.stop();

        printf("#1: Elapsed time: %lu usecs\n", sw.elapsed!"usecs");
    }

    {
        auto sw = StopWatch(true);

        sw.sleep!"usecs"(10);
        assert(sw.elapsed!"usecs" >= 10);

        sw.stop();

        printf("#2: Elapsed time: %lu usecs\n", sw.elapsed!"usecs");
    }

    {
        auto sw = StopWatch(true);

        sw.sleep!"msecs"(2);
        assert(sw.elapsed!"msecs" == 2);
        assert(sw.running() == true);
        sw.stop();

        printf("#3: Elapsed time: %lu usecs\n", sw.elapsed!"usecs");
    }

```
