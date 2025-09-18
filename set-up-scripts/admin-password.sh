cp "/fuseki/set-up-resources/shiro.ini" "$FUSEKI_BASE/shiro.ini"
if [ -z "$ADMIN_PASSWORD" ] ; then
    # Generate a random password using openssl (available in most containers)
    ADMIN_PASSWORD=$(openssl rand -base64 12 2>/dev/null || echo "admin")
    echo "Randomly generated admin password:"
    echo ""
    echo "admin=$ADMIN_PASSWORD"
fi
# Use | as delimiter instead of / to avoid issues with passwords containing /
sed -i "s|^admin=.*|admin=$ADMIN_PASSWORD|" "$FUSEKI_BASE/shiro.ini"