#!/bin/bash

echo "..Se clona el repo"
git clone https://github.com/CORE-UPM/quiz_2019.git 1>/dev/null
cd quiz_2019
mkdir /root/quiz_2019/public/uploads
echo "..Se instalan las dependencias"
npm install 1>/dev/null
if [ $? -eq 0 ]; then
  echo "...dependencias instaladas"
fi
npm install -g forever 1>/dev/null
if [ $? -eq 0 ]; then
  echo "...forever instalado"
fi
npm install mysql2 1>/dev/null
if [ $? -eq 0 ]; then
  echo "...mysql/mariadb instalado"
fi
echo "..Se configuran las variables de entorno"
export QUIZ_OPEN_REGISTER='yes'
echo "export QUIZ_OPEN_REGISTER=yes" >> /root/.bashrc
export DATABASE_URL='mysql://root:xxxx@10.1.2.10:3306/quiz'
echo "export DATABASE_URL='mysql://root:xxxx@10.1.2.10:3306/quiz'" >> /root/.bashrc