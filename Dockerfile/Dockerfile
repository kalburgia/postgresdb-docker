FROM postgres:11.2
COPY initdb/ /docker-entrypoint-initdb.d/
VOLUME /var/lib/postgresql/gwaydata
ENV POSTGRES_USER=gatewaydbsys
ENV POSTGRES_PASSWORD=gatewaydb$y$
ENV POSTGRES_DATABASE=postgres
ENV GWAYDATA /var/lib/postgresql/gwaydata
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 5432
CMD ["postgres"]

