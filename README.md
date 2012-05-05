cloudcrontab-web
================
Webapp running on www.cloudcrontab.com that uses api.cloudcrontab.com. This app is a static app, that can be (and actually is) served on AWS S3.

## Quick development
Use [webc](http://github.com/pboos/node-webc) to compile the code as you write it. That way you can just save the coffee-script/jade/less files and refresh the browser.

```bash
$ npm install -g webc
$ webc serve
```