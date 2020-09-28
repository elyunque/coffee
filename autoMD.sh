ITEM=$2
COLLECTION=$1
ASSETDIRECTUS=/var/www/html/public/uploads/lolo/originals/
CONFIGPATH=/root/coffee/
ASSETHUGO=/root/coffee/static/img/

[ "$3" == "md" ] && SWITCH=": " || SWITCH=" = "

echo "---"
while read ROW
do

  FIELD=`echo $ROW | cut -d' ' -f1`
  TYPE=`echo $ROW | cut -d' ' -f2`

  case "$TYPE" in
    owner|user_updated) 
      mysql -ss direc -e "SELECT CONCAT('$FIELD', CHAR(34), first_name, ' ', last_name, CHAR(34)) \
        FROM $COLLECTION main \
        LEFT JOIN directus_users ON main.$FIELD = directus_users.id \
        WHERE main.id=$ITEM;"
	  ;;
  integer) 
      mysql -ss direc -e "SELECT IF('$FIELD'='id', CONCAT('weight: ', main.$FIELD), CONCAT('$FIELD: ', main.$FIELD)) \
        FROM $COLLECTION main \
        WHERE main.id=$ITEM;"
      ;;
    status) 
      mysql -ss direc -e "SELECT IF(main.$FIELD='published', 'draft: false', 'draft: true') \
        FROM $COLLECTION main \
        WHERE main.id=$ITEM;"
      ;;
    datetime_updated|datetime_created) 
      mysql -ss direc -e "SELECT CONCAT('$FIELD: ', CHAR(34), CONVERT_TZ(main.$FIELD,'+00:00',@@global.time_zone), CHAR(34)) \
        FROM $COLLECTION main \
        WHERE main.id=$ITEM;"
      ;;
    file) 
      FILE=`mysql -ss direc -e "SELECT directus_files.filename_disk \
        FROM $COLLECTION main \
        LEFT JOIN directus_files ON main.$FIELD = directus_files.id \
        WHERE main.id=$ITEM;"`
        echo "$FIELD: \"img/$FILE\""
        \cp $ASSETDIRECTUS/$FILE $ASSETHUGO > /dev/null 2>&1
      ;;
    alias) 
      #Hacer nada
      ;;
    *) 
      if [ "$FIELD" == "content" ]
      then
        CONTENT=`mysql -ss direc -e "SELECT main.$FIELD FROM $COLLECTION main WHERE main.id=$ITEM;"`
      else
        mysql -ss direc -e "SELECT CONCAT('$FIELD: ', CHAR(34), main.$FIELD, CHAR(34)) \
          FROM $COLLECTION main \
          WHERE main.id=$ITEM;"
       fi
      ;;
  esac

done < <(mysql -ss direc -e "SELECT field, type FROM directus_fields WHERE collection='$COLLECTION' ORDER BY sort;")
echo "---"
echo $CONTENT