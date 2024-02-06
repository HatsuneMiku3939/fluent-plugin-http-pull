# fluent-plugin-http-pull

[![Build Status](https://travis-ci.org/HatsuneMiku3939/fluent-plugin-http-pull.svg?branch=master)](https://travis-ci.org/HatsuneMiku3939/fluent-plugin-http-pull)
[![Build status](https://ci.appveyor.com/api/projects/status/k91x4jyhahoo2it3?svg=true)](https://ci.appveyor.com/project/HatsuneMiku3939/fluent-plugin-http-pull)
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-http-pull.svg)](https://badge.fury.io/rb/fluent-plugin-http-pull)
[![Gem Downloads](https://img.shields.io/gem/dt/fluent-plugin-http-pull)](https://img.shields.io/gem/dt/fluent-plugin-http-pull)
[![Coverage Status](https://coveralls.io/repos/github/HatsuneMiku3939/fluent-plugin-http-pull/badge.svg?branch=master)](https://coveralls.io/github/HatsuneMiku3939/fluent-plugin-http-pull?branch=master)


[Fluentd](http://fluentd.org/) input plugin to pull log from rest api.

Many of modern server application offer status reporting API via http (even 'fluentd' too).
This plugin will help to gathering status log from these status api.

* [Installation](#installation)
* [Usage](#usage)
	* [Basic Usage](#basic-usage)
	* [Monitor Status Code](#monitoring-http-status-code-only)
	* [Override User Agent](#override-user-agent)
	* [HTTP Basic Auth](#http-basic-auth)
	* [HTTP Proxy](#http-proxy)
	* [Logging Response Header](#logging-http-response-header)
	* [Custom Request Header](#custom-request-header)
	* [HTTPS Support](#https-support)
* [Configuration](#configuration)
	* [tag](#tag-string-required)
	* [url](#url-string-required)
	* [agent](#agent-string-optional-default-fluent-plugin-http-pull)
	* [interval](#interval-time-required)
	* [format](#format-required)
	* [status_only](#status_only-bool-optional-default-false)
	* [http_method](#http_method-enum-optional-default-get)
	* [timeout](#timeout-time-optional-default-10s)
	* [proxy](#proxy-string-optional-default-nil)
	* [user](#user-string-optional-default-nil)
	* [password](#password-string-optional-default-nil)
	* [response_header](#response_header-section-optional-default-nil)
	* [request_header](#response_header-section-optional-default-nil)
	* [verify_ssl](#verify_ssl-bool-optional-default-true)
	* [ca_path](#ca_path-string-optional-defualt-nil)
	* [ca_file](#ca_file-string-optional-defualt-nil)
* [Version Tested](#version-tested)
* [Copyright](#copyright)

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

## Usage

### basic usage

In your Fluentd configuration, use @type http_pull.
`tag`, `url`, `interval`, `format` is mandatory configuration.

```
<source>
	@type http_pull

	tag status
	url http://your-infrastructure/api/status.json
	interval 1s

	format json
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/api/status.json","status":200,"message":{ ... }}
```

In this example, a response of your infrastructure parsed as json.
A result contains `url`, `status`, `message`.	`message` is a response of your infrastructure.

```
{
	"url": "http://your-infrastructure/api/status.json",
	"status": 200,
	"message": {
		// response of your infra structure
	}
}
```

You can found more examples in this document.

### Monitoring http status code only

If you need only http status code, not response body, You can turn off response
body parser to set `status_only` is true. Remember that `format` is mandatory.
In this case, you must set `format` is none.


```
<source>
	@type http_pull

	tag fluentd.status
	url http://your-infrastructure/healthcheck
	interval 1s

	status_only true
	format none
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/healthcheck","status":200}
```

### Override User Agent

You can set the User Agent by specifying the `agent` option.

```
<source>
	@type http_pull

	tag status
	url http://your-infrastructure/api/status.json
	interval 1s

	format json
	agent infrastructure_monitor
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/api/status.json","status":200,"message":{ ... }}
```

### HTTP basic auth

If your infrastructure is protected by HTTP basic auth,
You can use `user`, `password` options to provide authentication information.

```
<source>
	@type http_pull

	tag status
	url http://your-infrastructure/api/status.json
	interval 1s

	format json
	user foo
	password bar
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/api/status.json","status":200,"message":{ ... }}
```

### HTTP proxy

You can send your requests via proxy server.

```
<source>
	@type http_pull

	tag status
	url http://your-infrastructure/api/status.json
	proxy http://your-proxy-server:3128
	interval 1s

	format json
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/api/status.json","status":200,"message":{ ... }}
```

### Logging HTTP response header

If you wish to monitoring not only response body but also response header,
provide name of header in `response_header` sections.

```
<source>
	@type http_pull

	tag status
	url http://your-infrastructure/api/status.json
	interval 1s

	format json

	<response_header>
		header Content-Type
	</response_header>

	<response_header>
		header Content-Length
	</response_header>
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/api/status.json","status":200,"message":{ ... }}
```


### Custom request header

The custom request header also supported.
This will help you when your infrastructure needs authentication headers or something like that.

```
<source>
	@type http_pull

	tag status
	url http://your-infrastructure/api/status.json
	interval 1s

	format json

	<request_header>
		header API_ACCESS_KEY
		value hatsune
	</request_header>

	<response_header>
		header API_ACCESS_KEY_SECRET
		value miku
	</response_header>
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/api/status.json","status":200,"message":{ ... }}
```


### HTTPS support

If your infrastructure has https endpoints, just use https url for monitoring them.

#### self-signed SSL


If your infrastructure has https endpoints secured by self signed certification,
you can provide custom certification file via `ca_path`, `ca_file` option.

```
<source>
	@type http_pull

	tag status
	url https://your-infrastructure/api/status.json
	interval 1s
	ca_path /somewhere/ca/stored
	ca_file /somewhere/ca/stored/server.crt

	format json
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/api/status.json","status":200,"message":{ ... }}
```

And, disable SSL verification also supported. (not recommended)

```
<source>
	@type http_pull

	tag status
	url https://your-infrastructure/api/status.json
	interval 1s
	verify_ssl false

	format json
</source>

# 2017-05-17 21:41:47.872951000 +0900 status: {"url":"http://yourinfrastructure/api/status.json","status":200,"message":{ ... }}
```

## Configuration

### Basic Configuration

#### tag (string) (required)

The tag of the event.

#### url (string) (required)

The url of remote server.

#### agent (string) (optional, default: fluent-plugin-http-pull)

The user agent string of request.

#### interval (time) (required)

The interval time between periodic request.

#### format (required)

The format of the response body. Due to limitation of current implement it is
always required regardless `status_only` option.

`http_pull` uses parse plugin to parse the response body. See
[parser article](https://docs.fluentd.org/v0.12/articles/parser-plugin-overview)
for more detail.

#### status_only (bool) (optional, default: false)

If `status_only` is true, body is not parsed.

#### http_method (enum) (optional, default: :get)

The http request method for each requests. Avaliable options are listed below.

* `get`
* `post`
* `delete`

If `status_only` is true, `http_method` was override to `head`

#### timeout (time) (optional, default: 10s)

The timeout of each request.

### Proxy Configuration

#### proxy (string) (optional, default: nil)

The HTTP proxy URL to use for each requests

### Basic Auth Configuration

#### user (string) (optional, default: nil)

The user for basic auth

#### password (string) (optional, default: nil)

The password for basic auth

### Req/Resp Header Configuration

#### response_header (section) (optional, default: nil)

The name of response header for capture.

#### request_header (section) (optional, default: nil)

The name, value pair of custom reuqest header.

### SSL Configuration

#### verify_ssl (bool) (optional, default: true)

When false, SSL verification is ignored.

#### ca_path (string) (optional, defualt: nil)

The absolute path of directory where ca_file stored. Should be used with `ca_file`.

#### ca_file (string) (optional, defualt: nil)

The absolute path of ca_file. Should be used with `ca_path`.

## Version tested

This plugin is tested with the following version combination of ruby and fluentd.

| http_pull | ruby | fluentd    |
| --------- | ---- | ---------- |
| <= v0.7.0 | 2.3  | v0.14.x    |
| v0.8.0    | 2.3  | >= v1.0.0  |
| v0.8.1    | 2.3  | <= v1.14.4 |
| v0.8.2    | 2.3  | <= v1.14.4 |
| v0.8.3    | 2.3  | <= v1.14.4 |

## Copyright

* Copyright(c) 2017- filepang
* License
	* Apache License, Version 2.0
