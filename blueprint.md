
# Blueprint de la Aplicación de Abarrotes

## Visión General

Esta es una aplicación de Flutter para una tienda de abarrotes. Permite a los usuarios autenticarse, ver productos, realizar compras con un flujo de pago detallado y ver su historial de órdenes.

## Estilo y Diseño

*   **Tema**: Claro con `Colors.blue` como color principal.
*   **Fuentes**: `GoogleFonts` con "Poppins".
*   **Iconos**: `Material` y `FontAwesome`.
*   **Diseño**: Limpio, moderno, con tarjetas, gradientes y navegación intuitiva.

## Características

*   **Autenticación y Roles**: Login/registro con Firebase Auth, roles de Admin/Cliente, y sesión de invitado.

*   **Navegación Principal**: Barra de navegación inferior con "Home", "Historial" y "Perfil".

*   **Gestión de Productos**: CRUD para administradores y vista de cliente con botón de "Añadir al Carrito".

*   **Flujo de Compra Detallado**:
    *   **Carrito (`CartScreen`)**: Muestra los productos, permite modificar cantidades y calcula el costo (subtotal + envío).
    *   **Checkout (`CheckoutScreen`)**: Al "Proceder al Pago", se navega a esta pantalla que contiene un formulario para capturar:
        *   Nombre completo, teléfono y dirección.
        *   Selección de método de pago (Efectivo o Tarjeta).
        *   Campo condicional para el número de tarjeta.
    *   **Lógica de Pago**: El botón "Pagar Ahora" en la pantalla de checkout valida los datos y registra la orden en Firestore.

*   **Historial de Compras (`HistoryScreen`)**: Muestra una lista de las órdenes pasadas del usuario, obtenidas en tiempo real desde Firestore.

*   **Pantalla de Perfil (`ProfileScreen`)**: Muestra información básica del usuario.

## Estructura de la Base de Datos

*   **Colección `ordenes`**: Guarda el historial de compras.
    *   **Campos**:
        *   `userId` (String): ID del usuario.
        *   `items` (List<Map>): Lista de productos.
        *   `costoTotal` (double): Costo final.
        *   `fecha` (Timestamp): Fecha de la compra.
        *   `nombreCliente` (String): Nombre del cliente.
        *   `telefono` (String): Teléfono del cliente.
        *   `direccion` (String): Dirección de entrega.
        *   `metodoPago` (String): "Efectivo" o "Tarjeta".

## Plan de Implementación

*   **[Completado]** Implementación del Carrito de Compras.
*   **[Completado]** Implementación de la pantalla de Historial de Compras.
*   **[Completado]** **Mejora del Flujo de Pago con Formulario de Checkout**:
    *   Se creó la pantalla `lib/checkout_screen.dart` con un formulario para los datos del cliente y método de pago.
    *   La lógica de pago se movió a `CheckoutScreen`.
    *   La pantalla del carrito ahora redirige a `CheckoutScreen`.
