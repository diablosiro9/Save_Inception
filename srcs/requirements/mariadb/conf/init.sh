#!/bin/bash

# Check if the directory doesn't exist
if [ ! -d "/run/mysqld" ]; then
    mkdir -p /run/mysqld

    # Set the owner and group for the directory
    chown mysql:mysql /run/mysqld

    # Set the permissions for the directory to be more restrictive
    chmod 750 /run/mysqld
fi

if [ ! -d "/var/lib/mysql/mysql" ]; then
    chown -R mysql:mysql /var/lib/mysql
    mysql_install_db --basedir=/usr --datadir=/var/lib/mysql --user=mysql --rpm > /dev/null
    tfile=`mktemp`
    if [ ! -f "$tfile" ]; then
        return 1
    fi
    cat << EOF > $tfile
    USE mysql;
    FLUSH PRIVILEGES;
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE test;
    DELETE FROM mysql.db WHERE Db='test';
    DELETE FROM mysql.user WHERE User='$MDB_ROOT' AND Host NOT IN ('$MDB_HOST', '127.0.0.1', '::1');
    ALTER USER 'root'@'$MDB_HOST' IDENTIFIED BY '$MDB_ROOT_PWDD';
    CREATE DATABASE $MDB_NAME CHARACTER SET utf8 COLLATE utf8_general_ci;
    CREATE USER '$MDB_USER'@'%' IDENTIFIED by '$MDB_USER_PWD';
    GRANT ALL PRIVILEGES ON $MDB_NAME.* TO '$MDB_USER'@'%';
    GRANT ALL PRIVILEGES ON *.* TO '$MDB_USER'@'$MDB_HOST' IDENTIFIED BY '$MDB_USER_PWD';
    FLUSH PRIVILEGES;
EOF
    /usr/bin/mysqld --user=mysql --bootstrap < $tfile
    rm -f $tfile
fi

sed -i "s|skip-networking|# skip-networking|g" /etc/my.cnf.d/mariadb-server.cnf
sed -i "s|.*bind-address\s*=.*|bind-address=0.0.0.0|g" /etc/my.cnf.d/mariadb-server.cnf

exec /usr/bin/mysqld --user=mysql --console