import sys
import os
import boto3

stage = sys.argv[1]
directory = sys.argv[2]
bucket_name = sys.argv[3]

client = boto3.client('s3')

for file_name in os.listdir(directory):
    client.upload_file( directory + '/' + file_name,bucket_name,stage + '/' + file_name)

