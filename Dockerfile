FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl tar gzip ca-certificates && rm -rf /var/lib/apt/lists/*

# تنزيل حزمتك الذهبية v2.0 وفك ضغطها أثناء البناء لتكون جاهزة فوراً
RUN curl -L https://github.com/HazemAhmed01/mssql-2019-cloud/releases/download/v2.0/mssql_u20_golden.tar.gz | tar -xz -C /opt

# تقليل حد ذاكرة SQL Server إلى 384MB ليناسب حاوية Koyeb المجانية (512MB RAM)
RUN printf "[memory]\nmemorylimitmb = 384\n" > /opt/u20/var/opt/mssql/mssql.conf

# تنزيل أداة bore لتمرير منفذ TCP 1433 إلى هاتفك فوراً بدون إعدادات معقدة
RUN curl -L https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz | tar -xz -C /usr/local/bin

# خادم ويب مصغر على منفذ 8000 لإبقاء فحص الصحة (Health Check) الخاص بـ Koyeb نشطاً
CMD sh -c "mount --bind /proc /opt/u20/proc && \
           mount --bind /sys /opt/u20/sys && \
           mount --bind /dev /opt/u20/dev && \
           chroot /opt/u20 su -s /bin/bash mssql -c 'LD_PRELOAD=/opt/mssql/lib/libfake_mem.so ACCEPT_EULA=Y MSSQL_PID=Developer /opt/mssql/bin/sqlservr' & \
           sleep 5 && \
           bore local 1433 --to bore.pub & \
           python3 -m http.server 8000"
