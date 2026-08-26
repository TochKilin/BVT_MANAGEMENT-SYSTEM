# Veterinary clinic API

Run MongoDB locally, then start the API:

```bash
dart run bin/dart_api.dart
```

The server runs on port `8080`. The core endpoints are:

- `GET/POST /api/owners` — owners and their animals
- `GET/POST/DELETE /api/medicines` — medicine catalogue and batches
- `GET/POST/PUT/DELETE /api/records` — clinical records
- `GET/POST/PUT/DELETE /api/vaccinations` — vaccine doses and due dates
- `GET/POST/PUT/DELETE /api/appointments` — appointment scheduling
- `GET /api/dashboard/summary` — dashboard totals and alerts

Vaccination and appointment create requests require `owner_id`, `animal_id`, and respectively `vaccine_name` or `reason`.
