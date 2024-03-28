#!/bin/bash

set -e

MTLS_ALGO="rsa:8192"
HTTPS_ALGO="rsa:8192"

DURATION_DAYS=365

DEFAULT_C="NL"
DEFAULT_ST="North Holland"
DEFAULT_L="Amsterdam"
DEFAULT_O="Personal"
DEFAULT_OU="Personal"
DEFAULT_EMAIL="19146692+esaichik@users.noreply.github.com" #feel free to contact me with any questions by this email
DEFAULT_CN="localhost"

PG_USERS=(
    "superuser"
    "application_db_rw_user"
    "application_db_ro_user"
)

function cleanup {
    directories_to_clean=(
        "CA/https/"
        "CA/mtls/"
        "pg_general/client/"
        "pg_general/server/"
        "pgadmin_general/https/"
    )

    masks_to_remove=(
        "*.crt"
        "*.csr"
        "*.key"
        "*.srl"
        ".DS_Store"
    )

    for dir in "${directories_to_clean[@]}"
    do
        for mask in "${masks_to_remove[@]}"
        do
            echo "Removing" $dir$mask
            rm -rf $dir$mask
        done
    done
}


function generate_mtls_certificates {
    
    # initializing subject values
    MTLS_ROOT_CA_DN=/$(sed 's/^[ \t]*//' <<EOF | tr '\n' '/' | sed 's/\/$//'
        C=$DEFAULT_C
        ST=$DEFAULT_ST
        L=$DEFAULT_L
        O=$DEFAULT_O
        OU=$DEFAULT_OU
        emailAddress=$DEFAULT_EMAIL
        CN=$DEFAULT_CN
EOF)
    MTLS_SERVER_DN=/$(sed 's/^[ \t]*//' <<EOF | tr '\n' '/' | sed 's/\/$//'
        C=$DEFAULT_C
        ST=$DEFAULT_ST
        L=$DEFAULT_L
        O=$DEFAULT_O
        OU=$DEFAULT_OU
        emailAddress=$DEFAULT_EMAIL
        CN=$DEFAULT_CN
EOF)
    MTLS_CLIENT_DN=/$(sed 's/^[ \t]*//' <<EOF | tr '\n' '/' | sed 's/\/$//' 
        C=$DEFAULT_C
        ST=$DEFAULT_ST
        L=$DEFAULT_L
        O=$DEFAULT_O
        OU=$DEFAULT_OU
        emailAddress=$DEFAULT_EMAIL
        CN=
EOF)

    # mTLS root certificate
    echo "Generating mTLS root CSR and private key"
    umask u=rw,go= && \
        openssl req \
            -text \
            -nodes \
            -days $DURATION_DAYS \
            -newkey $MTLS_ALGO \
            -subj "$MTLS_ROOT_CA_DN" \
            -keyout CA/mtls/root.key \
            -out CA/mtls/root.csr
    echo "mTLS root CSR and private key generated"

    echo "Generating mTLS root (CA) certificate"
    umask u=rw,go= && \
        openssl x509 \
            -req \
            -text \
            -days $DURATION_DAYS \
            -in CA/mtls/root.csr \
            -extfile <(cat /etc/ssl/openssl.cnf v3.cnf) \
            -extensions v3_mtls_root \
            -signkey CA/mtls/root.key \
            -out CA/mtls/root.crt
    echo "mTLS root (CA) certificate generated"
    # mTLS root certificate end

    # mTLS server certificates
    echo "Generating mTLS pg_general server CSR and private key"
    umask u=rw,go= && \
        openssl req \
            -text \
            -nodes \
            -days $DURATION_DAYS \
            -newkey $MTLS_ALGO \
            -subj "$MTLS_SERVER_DN" \
            -keyout pg_general/server/server.key \
            -out pg_general/server/server.csr
    echo "mTLS pg_general server CSR and private key generated"

    echo "Generating mTLS pg_general server certificate using previously generated root certificate"
    umask u=rw,go= && \
        openssl x509 \
            -req \
            -text \
            -CAcreateserial \
            -days $DURATION_DAYS \
            -in pg_general/server/server.csr \
            -extfile <(cat /etc/ssl/openssl.cnf v3.cnf) \
            -extensions v3_mtls_server \
            -CA CA/mtls/root.crt \
            -CAkey CA/mtls/root.key \
            -out pg_general/server/server.crt
    echo "mTLS pg_general server certificate generated"
    # mTLS server certificates end

    # mTLS clients certificates
    for pg_user in "${PG_USERS[@]}"
    do
        echo "Generating mTLS pg_general client CSR and private key for $pg_user"
        umask u=rw,go= && \
            openssl req \
                -text \
                -nodes \
                -days $DURATION_DAYS \
                -newkey $MTLS_ALGO \
                -subj "$MTLS_CLIENT_DN"$pg_user \
                -keyout pg_general/client/$pg_user.key \
                -out pg_general/client/$pg_user.csr
        echo "mTLS pg_general client CSR and private key for $pg_user generated"

        echo "Generating mTLS pg_general client certificate for $pg_user using previously generated root certificate"
        umask u=rw,go= && \
            openssl x509 \
                -req \
                -text \
                -CAcreateserial \
                -days $DURATION_DAYS \
                -in pg_general/client/$pg_user.csr \
                -extfile <(cat /etc/ssl/openssl.cnf v3.cnf) \
                -extensions v3_mtls_client \
                -CA CA/mtls/root.crt \
                -CAkey CA/mtls/root.key \
                -out pg_general/client/$pg_user.crt
        echo "mTLS pg_general client certificate for $pg_user generated"
    done
    # mTLS clients certificates end

    echo "mTLS certificates generated"
}

function generate_https_certificates {

    # initializing subject values
    HTTPS_ROOT_CA_DN=/$(sed 's/^[ \t]*//' <<EOF | tr '\n' '/' | sed 's/\/$//'
        C=$DEFAULT_C
        ST=$DEFAULT_ST
        L=$DEFAULT_L
        O=$DEFAULT_O
        OU=$DEFAULT_OU
        emailAddress=$DEFAULT_EMAIL
        CN=$DEFAULT_CN
EOF)
    HTTPS_SERVER_DN=/$(sed 's/^[ \t]*//' <<EOF | tr '\n' '/' | sed 's/\/$//'
        C=$DEFAULT_C
        ST=$DEFAULT_ST
        L=$DEFAULT_L
        O=$DEFAULT_O
        OU=$DEFAULT_OU
        emailAddress=$DEFAULT_EMAIL
        CN=$DEFAULT_CN
EOF)

    # HTTPS root certificate
    echo "Generating HTTPS root CSR and private key"
    umask u=rw,go= && \
        openssl req \
            -text \
            -nodes \
            -days $DURATION_DAYS \
            -newkey $HTTPS_ALGO \
            -subj "$HTTPS_ROOT_CA_DN" \
            -keyout CA/https/root.key \
            -out CA/https/root.csr
    echo "HTTPS root CSR and private key generated"

    echo "Generating HTTPS root certificate"
    umask u=rw,go= && \
        openssl x509 \
            -req \
            -text \
            -days $DURATION_DAYS \
            -in CA/https/root.csr \
            -extfile <(cat /etc/ssl/openssl.cnf v3.cnf) \
            -extensions v3_https_root \
            -signkey CA/https/root.key \
            -out CA/https/root.crt
    echo "HTTPS root certificate generated"
    # HTTPS root certificate end

    # HTTPS server certificates
    echo "Generating HTTPS pgadmin_general server CSR and private key"
    umask u=rw,go= && \
        openssl req \
            -text \
            -nodes \
            -days $DURATION_DAYS \
            -newkey $HTTPS_ALGO \
            -subj "$HTTPS_SERVER_DN" \
            -keyout pgadmin_general/https/server.key \
            -out pgadmin_general/https/server.csr
    echo "HTTPS pgadmin_general server CSR and private key generated"

    echo "Generating HTTPS pgadmin_general server certificate using previously generated root certificate"
    umask u=rw,go= && \
        openssl x509 \
            -req \
            -text \
            -CAcreateserial \
            -days $DURATION_DAYS \
            -in pgadmin_general/https/server.csr \
            -extfile <(cat /etc/ssl/openssl.cnf v3.cnf) \
            -extensions v3_https_server \
            -CA CA/https/root.crt \
            -CAkey CA/https/root.key \
            -out pgadmin_general/https/server.crt
    echo "HTTPS pgadmin_general server certificate generated"
    # HTTPS server certificates end

    echo "HTTPS certificates generated"
}

function do_clean {
    echo "Cleaning up existing certificates data"
    cleanup
    echo "Existing certificates data cleaned up"
}

function do_generate {
    echo "Generating certificates..."
    generate_mtls_certificates
    generate_https_certificates
    echo "mTLS and HTTPS certificates generated"
    echo "mTLS clients certificates generated for $(IFS=','; echo "${PG_USERS[*]}")"
}

function show_help {
    echo "Usage: $0 [--mtls-algo=<MTLS algorithm>] [--https-algo=<HTTPS algorithm>] [--duration=<duration in days of certificate validity>] [--db-users=<comma separated list of users>] [--default-c=<country>] [--default-st=<state>] [--default-l=<locality>] [--default-o=<organization>] [--default-ou=<organizational unit>] [--default-email=<email>] [--default-cn=<common name>] [--skip-deletion] [--skip-generation]"
    echo "Defaults: [--mtls-algo=RSA:8192] [--https-algo=RSA:8192] [--duration=365] [--db-users=$(IFS=','; echo "${PG_USERS[*]}")] [--default-c=NL] [--default-st=\"North Holland\"] [--default-l=Amsterdam] [--default-o=Personal] [--default-ou=Personal] [--default-email=19146692+esaichik@users.noreply.github.com] [--default-cn=localhost] [--skip-deletion is not set] [--skip-generation is not set]"
}

function main {
    skip_deletion=false
    skip_generation=false
    for i in "$@"
    do
    case $i in
        --mtls-algo=*)
        MTLS_ALGO="${i#*=}"
        shift
        ;;
        --https-algo=*)
        HTTPS_ALGO="${i#*=}"
        shift
        ;;
        --duration=*)
        DURATION_DAYS="${i#*=}"
        shift
        ;;
        --default-c=*)
        DEFAULT_C="${i#*=}"
        shift
        ;;
        --default-st=*)
        DEFAULT_ST="${i#*=}"
        shift
        ;;
        --default-l=*)
        DEFAULT_L="${i#*=}"
        shift
        ;;
        --default-o=*)
        DEFAULT_O="${i#*=}"
        shift
        ;;
        --default-ou=*)
        DEFAULT_OU="${i#*=}"
        shift
        ;;
        --default-email=*)
        DEFAULT_EMAIL="${i#*=}"
        shift
        ;;
        --default-cn=*)
        DEFAULT_CN="${i#*=}"
        shift
        ;;
        --db-users=*)
        IFS=',' read -ra PG_USERS <<< "${i#*=}"
        shift
        ;;
        --skip-deletion)
        skip_deletion=true
        shift
        ;;
        --skip-generation)
        skip_generation=true
        shift
        ;;
        *)
        ;;
    esac
    done

    if [[ "$skip_deletion" != true ]]; then
        do_clean
    fi

    if [[ "$skip_generation" != true ]]; then
        do_generate
    fi
}

main $@
