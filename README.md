# bref-extensions
We use ghostscript, imagemagick, and libvips extensively in lambda. These executables, along with imagick and vips PHP extensions, are compiled to run on top of a bref (PHP 7.3) layer.

## Usage
To use this layer you need to import the appropriate bref layer into your Lambda first. For example using AWS SAM:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Resources:
    DemoFunction:
        Type: AWS::Serverless::Function
        Runtime: provided
        Properties:
            [...]
            Layers:
                - 'arn:aws:lambda:us-east-1:209497400698:layer:php-73:1'
                - 'arn:aws:lambda:us-east-1:965741605173:layer:sts-bref-extensions:1'
```
This will make the following available to your bref based project:
```
sh-4.2# pwd
/opt/bin
sh-4.2# ls -al
total 8
drwxr-xr-x 1 root root 4096 Feb  5 19:33 .
drwxr-xr-x 1 root root 4096 Feb  5 19:33 ..
lrwxrwxrwx 1 root root   20 Feb  5 19:33 convert -> /opt/sts/bin/convert
lrwxrwxrwx 1 root root   15 Feb  5 19:33 gs -> /opt/sts/bin/gs
lrwxrwxrwx 1 root root   21 Feb  5 19:33 identify -> /opt/sts/bin/identify
lrwxrwxrwx 1 root root   17 Feb  5 19:33 vips -> /opt/sts/bin/vips
lrwxrwxrwx 1 root root   26 Feb  5 19:33 vipsthumbnail -> /opt/sts/bin/vipsthumbnail
sh-4.2# convert --version
Version: ImageMagick 6.9.10-10 Q16 x86_64 2019-02-05 https://www.imagemagick.org
Copyright: © 1999-2018 ImageMagick Studio LLC
License: https://www.imagemagick.org/script/license.php
Features: Cipher DPC HDRI OpenMP
Delegates (built-in): bzlib jng jpeg lcms png tiff xml zlib
sh-4.2# gs --version
9.26
sh-4.2# identify --version
Version: ImageMagick 6.9.10-10 Q16 x86_64 2019-02-05 https://www.imagemagick.org
Copyright: © 1999-2018 ImageMagick Studio LLC
License: https://www.imagemagick.org/script/license.php
Features: Cipher DPC HDRI OpenMP
Delegates (built-in): bzlib jng jpeg lcms png tiff xml zlib
sh-4.2# vips --version
vips-8.7.0-Fri Aug 31 14:11:19 UTC 2018
```
as well as the following PHP extensions:
```
sh-4.2# pwd
/opt/sts/modules
sh-4.2# ls -al
total 1288
drwxr-xr-x 1 root root    4096 Feb  5 19:17 .
drwxr-xr-x 1 root root    4096 Feb  5 19:33 ..
-rwxr-xr-x 1 root root 1158960 Feb  5 15:57 imagick.so
-rwxr-xr-x 1 root root  149751 Feb  5 19:17 vips.so
```

## Installation
```
git clone git@github.com:stechstudio/bref-extensions.git
git submodule init bref
make
```

## Make Targets
* **config** - Generates a docker file for us by extracting from the bref php build docker file.
* **php** - Builds the php docker image.
* **extensions** - Builds the extensions and executables in the php docker image.
* **zip** - Copys the archived files out of the php docker container.
* **publish** - Publishes the layer to AWS.


