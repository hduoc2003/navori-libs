module lib_addr::bytes {
    use std::bcs::to_bytes;
    use std::option;
    use std::option::Option;
    use std::signer::address_of;
    use std::vector;
    use std::vector::{append, for_each_ref, length, borrow};
    use aptos_std::from_bcs::to_u256;

    // Pads a vector<u8> with a specified byte value up to the desired length
    public fun pad(v: vector<u8>, desired_length: u64, pad_byte: u8, pad_left: bool): vector<u8> {
        let current_length = vector::length(&v);

        if (current_length >= desired_length) {
            return v
        };

        let pad = vector::empty<u8>();
        let pad_length = desired_length - current_length;

        let i = 0;
        while (i < pad_length) {
            vector::push_back(&mut pad, pad_byte);
            i = i + 1;
        };

        let padded = vector[];

        if (pad_left) {
            vector::append(&mut padded, v);
            vector::append(&mut padded, pad);
        } else {
            vector::append(&mut padded, pad);
            vector::append(&mut padded, v);
        };

        return padded
    }

    public fun reverse(x: vector<u8>): vector<u8> {
        let result = vector::empty<u8>();
        let length = vector::length(&x);
        let i = 0;

        while (i < length) {
            let byte = vector::borrow(&x, length - 1 - i);
            vector::push_back(&mut result, *byte);
            i = i + 1;
        };

        return result
    }

    public fun long_vec_to_bytes_be<Element>(signer: &signer, v: &vector<Element>): Option<vector<u8>> acquires Checkpoint, Cache {
        let signer_addr = address_of(signer);
        if (!exists<Checkpoint>(signer_addr)) {
            move_to(signer, Checkpoint {
                inner: IN_ITERATION
            })
        };
        let Checkpoint {
            inner: checkpoint
        } = borrow_global_mut<Checkpoint>(signer_addr);
        if (!exists<Cache>(signer_addr)) {
            move_to(signer, Cache {
                ptr: 0,
                bytes: vector[]
            })
        };
        let Cache {
            ptr,
            bytes
        } = borrow_global_mut<Cache>(signer_addr);
        if (*checkpoint == IN_ITERATION) {
            let n = length(v);
            let count = 0;
            while (*ptr < n && count < ITERATION_LENGTH) {
                let tmp = to_bytes(borrow(v, *ptr));
                vector::reverse(&mut tmp);
                append(bytes, tmp);
                *ptr = *ptr + 1;
                count = count + 1;
            };
            if (*ptr < n) {
                return option::none<vector<u8>>()
            };
            *checkpoint = END_ITERATION;
        };
        let bytes = *bytes;
        move_from<Checkpoint>(signer_addr);
        move_from<Cache>(signer_addr);
        option::some(bytes)
    }

    public fun vec_to_bytes_be<Element>(v: &vector<Element>): vector<u8> {
        let bytes: vector<u8> = vector[];
        for_each_ref(v, |e| {
            let tmp = to_bytes(e);
            vector::reverse(&mut tmp);
            append(&mut bytes, tmp);
        });
        bytes
    }

    public fun num_to_bytes_be<Element>(v: &Element): vector<u8> {
        let res = to_bytes(v);
        vector::reverse(&mut res);
        res
    }

    public fun u256_from_bytes_be(bytes: &vector<u8>): u256 {
        let r_bytes = *bytes;
        vector::reverse(&mut r_bytes);
        to_u256(r_bytes)
    }

    // Data of the function `long_vec_to_bytes_be`

    // checkpoints
    const IN_ITERATION: u8 = 1;
    const END_ITERATION: u8 = 1;

    const ITERATION_LENGTH: u64 = 1000;

    struct Cache has key, drop {
        ptr: u64,
        bytes: vector<u8>
    }

    struct Checkpoint has key, drop {
        inner: u8
    }
}

#[test_only]
module lib_addr::bytes_test {
    use std::bcs::to_bytes;
    use std::vector;
    use aptos_std::debug::print;

    use lib_addr::bytes::{pad, vec_to_bytes_be};

    #[test]
    fun test_padding() {
        let value = 0x123456;
        let v = to_bytes(&value);
        print(&v);
        let padded = pad(v, 32, 0x00, true);
        // Debug print or other test verification steps can be added here
        assert!(vector::length(&padded) == 32, 1);
        assert!(padded == to_bytes(&0x123456u256), 1);
    }

    #[test]
    fun test_vec_to_bytes_be() {
        let bytes = vec_to_bytes_be(&vector[
            1723587082856532763241173775465496577348305577532331450336061658809521876102u256,
            2479248348687909740970436565718726357572221543762678024250834744245756360726u256,
            587272u256,
            2177570517647428816133395681679456086343281988787809822104528418476218261377u256,
            2590421891839256512113614983194993186457498815986333310670788206383913888162u256,
            0u256,
            0u256
        ]);
        assert!(
            bytes == vector[3, 207, 132, 6, 22, 251, 16, 23, 61, 164, 114, 227, 144, 90, 144, 182, 125, 246, 14, 114, 141, 124, 226, 100, 55, 247, 9, 238, 226, 83, 44, 134, 5, 123, 52, 112, 61, 135, 118, 240,
                24, 28, 235, 230, 182, 104, 65, 168, 12, 194, 199, 51, 49, 197, 88, 205, 129, 152, 95, 217, 19, 67, 248, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                , 0, 0, 0, 0, 8, 246, 8, 4, 208, 118, 19, 147, 125, 138, 113, 9, 211, 33, 204, 68, 209, 67, 44, 185, 149, 186, 61, 135, 177, 85, 80, 221, 169, 41, 202, 199, 30, 31, 129, 5, 186, 32,
                120, 36, 15, 21, 133, 249, 100, 36, 194, 209, 238, 72, 33, 29, 163, 179, 249, 23, 123, 242, 185, 136, 11, 79, 201, 29, 89, 233, 162, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                , 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            1
        );
    }
}