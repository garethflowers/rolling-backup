# Rolling Backup

An `rsync` based incremental backup script.

# Usage

```sh
./src/backup.sh SOURCE DESTINATION JOBNAME
```

## Example

To copy the entire `/Users` directory to an external disk labelled "Backup"
(`/Volumes/Backup`), using a job name `users`.

```sh
./src/backup.sh /Users /Volumes/Backup users
```
```sh
ls /Volumes/Backup
# users
# users.1
# users.2
# users.3
```
