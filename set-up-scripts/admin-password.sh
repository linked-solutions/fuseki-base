cp "/fuseki/set-up-resources/shiro.ini" "$FUSEKI_BASE/shiro.ini"
if [ -z "$ADMIN_PASSWORD" ] ; then
    apt -qq update
    apt -qq install pwgen
    ADMIN_PASSWORD=$(pwgen -s 15)
    echo "Randomly generated admin password:"
    echo ""
    echo "admin=$ADMIN_PASSWORD"
fi
sed -i "s/^admin=.*/admin=$ADMIN_PASSWORD/" "$FUSEKI_BASE/shiro.ini"