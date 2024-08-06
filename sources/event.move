module lib_addr::event {
    use aptos_framework::account;
    use aptos_framework::event;
    use aptos_framework::event::destroy_handle;

    public fun log_event<T: store + drop>(signer: &signer, data: T) {
        let event_handler = account::new_event_handle<T>(signer);
        event::emit_event(&mut event_handler, data);
        destroy_handle<T>(event_handler);
    }
}
