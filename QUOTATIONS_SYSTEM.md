# Sistema de Cotizaciones - Documentación

## 📋 Descripción General

Se ha implementado un sistema completo de cotizaciones para Bellezapp que permite:

1. **Generar Cotizaciones** - Crear cotizaciones sin afectar el stock ni los datos de la app
2. **Gestionar Cotizaciones** - Ver todas las cotizaciones con filtros por estado y fecha
3. **Convertir a Venta** - Transformar una cotización en venta (solo cuando se convierte afecta el stock)

## 🏗️ Estructura Backend

### Modelo: `Quotation.ts`
Ubicación: `lock-backend/src/models/Quotation.ts`

Campos principales:
- `quotationDate` - Fecha de creación
- `expirationDate` - Fecha de expiración (30 días por defecto)
- `totalQuotation` - Total de la cotización
- `customerId` - Cliente asociado (opcional)
- `storeId` - Tienda asociada
- `items` - Array de productos
- `discountId` - Descuento aplicado (opcional)
- `discountAmount` - Monto del descuento
- `paymentMethod` - Método de pago (opcional)
- `status` - Estado: pending | converted | expired | cancelled
- `convertedOrderId` - ID de la orden si fue convertida

### Controlador: `quotation.controller.ts`
Ubicación: `lock-backend/src/controllers/quotation.controller.ts`

Endpoints:
- `GET /quotations` - Obtener todas las cotizaciones
- `GET /quotations/:id` - Obtener una cotización específica
- `POST /quotations` - Crear nueva cotización
- `POST /quotations/:quotationId/convert` - Convertir a orden
- `DELETE /quotations/:quotationId` - Cancelar cotización

### Rutas: `quotation.routes.ts`
Ubicación: `lock-backend/src/routes/quotation.routes.ts`

Todas las rutas requieren autenticación (JWT).

## 📱 Estructura Frontend (Flutter)

### Modelo: `quotation.dart`
Ubicación: `lock-movil/lib/models/quotation.dart`

Clases:
- `Quotation` - Representa una cotización completa
- `QuotationItem` - Representa un producto en la cotización

### Servicio: `quotation_service.dart`
Ubicación: `lock-movil/lib/services/quotation_service.dart`

Métodos:
- `getQuotations()` - Obtener cotizaciones con filtros
- `getQuotation(id)` - Obtener detalle de una cotización
- `createQuotation()` - Crear nueva cotización
- `convertQuotationToOrder()` - Convertir a venta
- `deleteQuotation()` - Cancelar cotización

### Controlador: `quotation_controller.dart`
Ubicación: `lock-movil/lib/controllers/quotation_controller.dart`

Propiedades observables (Rx):
- `quotations` - Lista de cotizaciones
- `isLoading` - Estado de carga
- `error` - Mensaje de error

### Página: `quotations_list_page.dart`
Ubicación: `lock-movil/lib/pages/quotations_list_page.dart`

Características:
- Lista completa de cotizaciones
- Filtros por estado (Pendiente, Convertida, Expirada, Cancelada)
- Filtros por rango de fechas
- Botón "Convertir a Venta" para cotizaciones pendientes
- Botón "Cancelar" para cancelar cotizaciones
- Indicadores visuales por estado
- Resumen de productos y total

## 🎯 Flujo de Uso

### Generar Cotización

#### Opción 1: Desde Add Order Page (QR)
1. Escanear productos con QR
2. Hacer clic en botón **"Generar Cotización"**
3. Se guarda en la BD sin afectar stock
4. Regresa a la lista de órdenes

#### Opción 2: Desde Add Order By Search Page
1. Buscar y seleccionar productos
2. Ajustar cantidades
3. Hacer clic en **"Generar Cotización"**
4. Se guarda en la BD sin afectar stock
5. Regresa a la lista de órdenes

### Gestionar Cotizaciones

1. Ir a **Drawer → Cotizaciones**
2. Ver lista de todas las cotizaciones
3. Filtrar por:
   - Estado (Pendiente, Convertida, Expirada, Cancelada)
   - Rango de fechas
4. Para cotizaciones pendientes:
   - **Convertir a Venta**: Se crea una orden, se descuenta stock, se suman puntos
   - **Cancelar**: Se marca como cancelada

## 🔄 Conversión de Cotización a Venta

Cuando se convierte una cotización a venta:

1. ✅ Se verifica stock disponible
2. ✅ Se descuenta stock de ProductStore
3. ✅ Se suman puntos al cliente (si existe)
4. ✅ Se crea el registro de CashMovement
5. ✅ Se crea la orden
6. ✅ La cotización se marca como convertida
7. ✅ Se vincula la orden con convertedOrderId

## 📊 Estados de Cotización

| Estado | Descripción | Acciones |
|--------|-------------|----------|
| `pending` | Cotización nueva, no procesada | Convertir a venta, Cancelar |
| `converted` | Se convirtió a orden (venta realizada) | Ninguna |
| `expired` | Expiró (después de 30 días) | Ninguna |
| `cancelled` | Fue cancelada manualmente | Ninguna |

## 🎨 Integración UI

### Botones Agregados

#### En Add Order Page (Escaneo QR)
- Botón **"Procesar Orden"** (azul) - Crear orden inmediatamente
- Botón **"Generar Cotización"** (naranja) - Guardar como cotización

#### En Add Order By Search Page
- Botón **"Crear Orden"** (azul) - Con diálogo de cliente, descuento, pago
- Botón **"Generar Cotización"** (naranja) - Guardar sin procesar

#### En Home Page Drawer
- Opción **"Cotizaciones"** (teal) - Abre lista de cotizaciones
- Posición: Bajo "Devoluciones"

## 🔒 Seguridad

- Todas las rutas requieren autenticación JWT
- Validación de stock al convertir
- Validación de datos en backend
- Solo usuarios autenticados pueden:
  - Ver cotizaciones
  - Crear cotizaciones
  - Convertir cotizaciones a venta

## 📝 Notas Importantes

1. **No afecta datos inicialmente** - Las cotizaciones se guardan sin tocar stock, puntos ni ingresos
2. **Afecta solo al convertir** - Solo cuando se convierte a venta se procesan todos los datos
3. **Expiración automática** - Se puede configurar período de expiración (default: 30 días)
4. **Historial completo** - Se mantiene el historial de todas las cotizaciones para auditoría

## 🚀 Próximas Mejoras Posibles

- [ ] Generar PDF de cotización
- [ ] Enviar cotización por email
- [ ] Validez de cotización personalizable por tienda
- [ ] Descuentos especiales por cotización
- [ ] Historial de cambios en cotización
- [ ] Reporte de cotizaciones no convertidas
