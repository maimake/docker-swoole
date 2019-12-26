<?php


go(function () {
    $redis = new Swoole\Coroutine\Redis();
    $redis->connect('redis', 6379);
    $redis->auth('123456');
    $res = $redis->set('key', 'xxxxx');
    var_dump($res);

    $val = $redis->get('key');
    var_dump($val);
});

