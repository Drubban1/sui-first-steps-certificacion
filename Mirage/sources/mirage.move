module mirage::mirage {
    use std::string::{String};
    use sui::object::{UID};
    use sui::tx_context::{TxContext, sender};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap}; 
    
    // Estructura principal de la tienda
    public struct Tienda has key, store {
        id: UID,
        nombre: String,
        videojuegos: VecMap<u64, Videojuego>,
        usuarios: VecMap<u64, Usuario>
    }

    // Estructura para videojuegos
    public struct Videojuego has store, copy, drop {
        id: u64,
        titulo: String,
        precio: u64,
        genero: Genero,
        en_venta: bool
    }

    // Estructura para usuarios
    public struct Usuario has store, drop {
        id: u64,
        nombre: String,
        biblioteca: vector<u64>,
        tipo_cuenta: TipoCuenta
    }

    // Tipos de cuenta
    public enum TipoCuenta has store, drop {
        basica(Basica),
        premium(Premium)
    }

    // Beneficios cuenta básica
    public struct Basica has store, drop {
        descuento: u8
    }

    // Beneficios cuenta premium  
    public struct Premium has store, drop {
        descuento: u8,
        juegos_gratis: u8
    }

    // Géneros de videojuegos
    public enum Genero has store, copy, drop {
        accion,
        aventura,
        rpg,
        estrategia,
        deportes
    }

    // Función para crear la tienda
    public fun crear_tienda(nombre: String, ctx: &mut TxContext) {
        let tienda = Tienda {
            id: object::new(ctx),
            nombre,
            videojuegos: vec_map::empty(),
            usuarios: vec_map::empty()
        };
        
        transfer::transfer(tienda, sender(ctx));
    }

    public fun agregar_videojuego(
        tienda: &mut Tienda, 
        id: u64, 
        titulo: String, 
        precio: u64
    ) {
        let videojuego = Videojuego {
            id,
            titulo,
            precio,
            genero: Genero::accion,  // Valor por defecto
            en_venta: true
        };
        
        tienda.videojuegos.insert(id, videojuego);
    }

    // Función para registrar usuarios
    public fun registrar_usuario(tienda: &mut Tienda, id: u64, nombre: String) {
        let usuario = Usuario {
            id,
            nombre,
            biblioteca: vector::empty(),
            tipo_cuenta: TipoCuenta::basica(Basica{descuento: 0})
        };
        
        tienda.usuarios.insert(id, usuario);
    }

    // Función para comprar juego
    public fun comprar_juego(tienda: &mut Tienda, id_usuario: u64, id_juego: u64) {
        let usuario = tienda.usuarios.get_mut(&id_usuario);
        vector::push_back(&mut usuario.biblioteca, id_juego);
    }

    // Función para actualizar a cuenta premium
    public fun actualizar_premium(tienda: &mut Tienda, id_usuario: u64) {
        let usuario = tienda.usuarios.get_mut(&id_usuario);
        usuario.tipo_cuenta = TipoCuenta::premium(Premium{
            descuento: 20,
            juegos_gratis: 2
        });
    }

    // Función para obtener descuento del usuario
    public fun obtener_descuento(tienda: &mut Tienda, id_usuario: u64): u8 {
        let usuario = tienda.usuarios.get_mut(&id_usuario);
        let tipo = &usuario.tipo_cuenta;
        
        match(tipo) {
            TipoCuenta::basica(basica) => basica.descuento,
            TipoCuenta::premium(premium) => premium.descuento
        }
    }

    // Función para cambiar estado de venta de un juego
    public fun cambiar_estado_venta(tienda: &mut Tienda, id_juego: u64, en_venta: bool) {
        let juego = tienda.videojuegos.get_mut(&id_juego);
        juego.en_venta = en_venta;
    }

    // Función para eliminar videojuego de la tienda
    public fun eliminar_videojuego(tienda: &mut Tienda, id_juego: u64) {
        tienda.videojuegos.remove(&id_juego);
    } 

    // Función para eliminar usuario
    public fun eliminar_usuario(tienda: &mut Tienda, id_usuario: u64) {
        tienda.usuarios.remove(&id_usuario);
    }

    // Función para remover juego de la biblioteca de usuario
    public fun remover_de_biblioteca(tienda: &mut Tienda, id_usuario: u64, id_juego: u64) {
        let usuario = tienda.usuarios.get_mut(&id_usuario);
        let biblioteca = &mut usuario.biblioteca;
        let len = vector::length(biblioteca);
        let mut i = 0;
        
        while (i < len) {
            let juego_id = vector::borrow(biblioteca, i);
            if (*juego_id == id_juego) {
                vector::remove(biblioteca, i);
                break
            };
            i = i + 1;
        };
    }
}