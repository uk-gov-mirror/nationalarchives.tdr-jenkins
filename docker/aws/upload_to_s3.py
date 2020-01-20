import sys
import os
import boto3

stage = sys.argv[1]

client = boto3.client('s3')

for file_name in os.listdir("migrations"):
    client.upload_file('migrations/' + file_name, 'tdr-database-migrations', stage + '/' + file_name)

