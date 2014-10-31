# PocketTrend

[Pocket](http://getpocket.com/)の記事追加数と記事読了数をグラフで表示

# How To

依存モジュールをインストール

```
carton install
```

起動

```
carton exec -- perl -Ilib script/pockettrend-server
```

# Docker

Docker imageを使用して起動

```
docker run -p 5000:5000 waniji/pocket-trend
```

# Author

[Makoto Sasaki](https://github.com/waniji/)

