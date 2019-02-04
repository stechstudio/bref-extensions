#!/usr/bin/env php
<?php
require __DIR__ . '/vendor/autoload.php';

use GuzzleHttp\Client;
use Aws\Lambda\LambdaClient;

$config = yaml_parse_file(__DIR__ . '/config.yml');

$client = LambdaClient::factory([
    'version' => '2015-03-31',
    'region'  => 'us-east-1'
]);

$result = $client->getLayerVersion($config['bref']);
$layer = ($result->get('Content'));

//(new Client())->request('GET', $layer['Location'], ['sink' => __DIR__ . '/bref-layer.zip']);

// open the input and the output
$fp = fopen(__DIR__ . '/bref/runtime/php/php.Dockerfile', 'r');
$out = fopen(__DIR__ . '/php.Dockerfile',"w");

while(($line = fgets($fp)) !== false){
    // but we don't want to proceed past installing PHP
    if ($line == "# Strip all the unneeded symbols from shared libraries to reduce size.\n"){
        // if so, break
        break;
    }
    fputs($out, $line);
}
fclose($fp);
fclose($out);
