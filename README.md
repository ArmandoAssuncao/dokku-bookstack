
## Dokku For [BookStack](https://github.com/ssddanbrown/BookStack)

### Quickstart
1. Create your container:  
  `dokku apps:create <app-name>`
2. Install Plugin [Dokku-Mysql](https://github.com/dokku/dokku-mysql)
3. Create and link mysql to your app:  
  `dokku mysql:create <mysql-name>`  
  `dokku mysql:link <mysql-name> <app-name>`
4. Set env `APP_KEY` and `APP_URL` to app:  
  `dokku config:set <app-name> APP_KEY=SomeRandomStringWith32Characters APP_URL=https://containerdomain.example`
5. Install and use plugins: [plugin timeout](https://github.com/danielslee/dokku-nginx-proxy-timeout), [plugin max upload](https://github.com/Zeilenwerk/dokku-nginx-max-upload-size)  
6. Push to dokku:  
  `git push dokku master`
7. gg!

#### Using S3 to storage images and files:
Set to app follow envs:
```
STORAGE_TYPE="s3"
STORAGE_S3_KEY="**KEY**"
STORAGE_S3_SECRET="**SECRET**"
STORAGE_S3_REGION="**REGION**"
STORAGE_S3_BUCKET="**BUCKET**"
```
Set if you using S3 custom domains/cdns:  
`STORAGE_URL="**URL**"`

Thanks for [docker-bookstack](https://github.com/solidnerd/docker-bookstack) <3
