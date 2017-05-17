# fluent-plugin-http-pull

[Fluentd](http://fluentd.org/) input plugin to pull log from rest api.

Many of modern server application offer status reporting API via http (even 'fluentd' too). This plugin will help to gathering status log from these status api.

## Installation

### RubyGems

```
$ gem install fluent-plugin-http-pull
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-http-pull"
```

And then execute:

```
$ bundle
```

## Example

### Monitoring http status code only
```
<source>
  @type http_pull

  tag test
  url http://www.google.com
  interval 1

  status_only true
</source>

<match test>
  @type stdout
</match>

# 2017-05-17 21:40:40.413219000 +0900 test: {"url":"http://www.google.com","status":200}
# 2017-05-17 21:40:41.298215000 +0900 test: {"url":"http://www.google.com","status":200}
# 2017-05-17 21:40:42.310993000 +0900 test: {"url":"http://www.google.com","status":200}
# 2017-05-17 21:40:43.305947000 +0900 test: {"url":"http://www.google.com","status":200}
```

### Monitoring fluentd itself
```
<source>
  @type monitor_agent

  port 24220
</source>

<source>
  @type http_pull

  tag test
  url http://localhost:24220/api/plugins.json
  interval 1

  status_only false
</source>

<match test>
  @type stdout
</match>

# 2017-05-17 21:41:47.872951000 +0900 test: {"url":"http://localhost:24220/api/plugins.json","status":200,"message":{"plugins":[{"plugin_id":"object:1e7e3d...
# 2017-05-17 21:41:48.955316000 +0900 test: {"url":"http://localhost:24220/api/plugins.json","status":200,"message":{"plugins":[{"plugin_id":"object:1e7e3d...
# 2017-05-17 21:41:50.033628000 +0900 test: {"url":"http://localhost:24220/api/plugins.json","status":200,"message":{"plugins":[{"plugin_id":"object:1e7e3d...
# 2017-05-17 21:41:51.107372000 +0900 test: {"url":"http://localhost:24220/api/plugins.json","status":200,"message":{"plugins":[{"plugin_id":"object:1e7e3d...
```


### Monitoring elasticsearch cluster health
```
<source>
  @type http_pull

  tag test
  url http://localhost:9200/_cluster/health
  interval 1

  status_only false
</source>

<match test>
  @type stdout
</match>

# 2017-05-17 12:49:09.886298008 +0000 test: {"url":"http://localhost:9200/_cluster/health","status":200,"message":{"cluster_name":"elasticsearch","status":"green",...
# 2017-05-17 12:49:10.669431296 +0000 test: {"url":"http://localhost:9200/_cluster/health","status":200,"message":{"cluster_name":"elasticsearch","status":"green",...
# 2017-05-17 12:49:11.668789668 +0000 test: {"url":"http://localhost:9200/_cluster/health","status":200,"message":{"cluster_name":"elasticsearch","status":"green",...
# 2017-05-17 12:49:12.668789849 +0000 test: {"url":"http://localhost:9200/_cluster/health","status":200,"message":{"cluster_name":"elasticsearch","status":"green",...
```

## Configuration

* See also: Fluent::Plugin::Input

## Fluent::Plugin::HttpPullInput

### tag (string) (required)

The tag of the event.

### url (string) (required)

The uri of monitoring target

### interval (integer) (required)

The second interval time between periodic request

### status_only (bool) (optional)

status_only

## Copyright

* Copyright(c) 2017- filepang
* License
  * Apache License, Version 2.0
