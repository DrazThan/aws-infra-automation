import boto3
import argparse

def main():
    parser = argparse.ArgumentParser(description='Manage EBS Snapshots.')
    parser.add_argument('--snapshot-name', required=True, help='Snapshot name')
    parser.add_argument('--volume-id', required=True, help='EBS Volume ID')
    parser.add_argument('--retain', type=int, default=5, help='Number of snapshots to retain')
    parser.add_argument('--region', default='us-east-1', help='AWS region')

    args = parser.parse_args()

    # Create EC2 client with specified region
    ec2 = boto3.client('ec2', region_name=args.region)

    try:
        # Create snapshot
        response = ec2.create_snapshot(
            VolumeId=args.volume_id,
            Description=args.snapshot_name
        )
        snapshot_id = response['SnapshotId']
        print(f"Created snapshot {snapshot_id}")

        # Retrieve existing snapshots
        snapshots = ec2.describe_snapshots(
            Filters=[
                {'Name': 'volume-id', 'Values': [args.volume_id]},
                {'Name': 'description', 'Values': [args.snapshot_name]}
            ],
            OwnerIds=['self']
        )['Snapshots']

        # Sort snapshots by date
        snapshots.sort(key=lambda x: x['StartTime'], reverse=True)

        # Delete old snapshots
        for snap in snapshots[args.retain:]:
            ec2.delete_snapshot(SnapshotId=snap['SnapshotId'])
            print(f"Deleted snapshot {snap['SnapshotId']}")

    except boto3.exceptions.NoCredentialsError:
        print("AWS credentials not found. Please configure your AWS credentials.")
        exit(1)
    except boto3.exceptions.BotoCoreError as e:
        print(f"AWS Error: {str(e)}")
        exit(1)

if __name__ == "__main__":
    main()