# Testes de integração

A suíte usa PostgreSQL, tal como a aplicação. Isso é obrigatório porque as consultas de busca usam recursos específicos do PostgreSQL, como `ILIKE`.

Na pasta da API, inicie o banco efêmero de testes:

```powershell
docker compose -f docker-compose.test.yml up -d --wait
php artisan test
docker compose -f docker-compose.test.yml down -v
```

O banco escuta em `127.0.0.1:55432` e é definido exclusivamente no `phpunit.xml`; nunca aponta para a base de desenvolvimento ou produção.
