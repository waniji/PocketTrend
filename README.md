# PocketTrend

[Pocket](http://getpocket.com/)の記事追加数と記事読了数をグラフで表示

# How To

Pocketのconsumer keyとaccess tokenを設定

```
vi config.pl
```

```
+{
    consumer_key => 'xxxxx',
    access_token => 'xxxxx',
};
```

依存モジュールをインストール

```
carton install
```

起動

```
carton exec -- perl -Ilib script/pockettrend-server
```

# Author

[Makoto Sasaki](https://github.com/waniji/)
