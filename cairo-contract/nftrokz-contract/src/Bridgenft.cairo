%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_equal, assert_not_zero, assert_nn_le, assert_lt

@storage_var
func owners(token_id : felt) -> (res : felt){
}

@storage_var
func balances(owner : felt) -> (res : felt){
}

@storage_var
func token_approvals(token_id : felt) -> (res : felt){
}

@storage_var
func operator_approvals(owner : felt, operator : felt) -> (res : felt){
}

@storage_var
func initialized() -> (res : felt){
}

@storage_var
func l1_address() -> (res : felt){
}

@storage_var
func gateway_address() -> (res : felt){
}

@storage_var
func total_supply_counter() -> (res : felt){
}





@external
func initialize{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(_l1_address : felt, _gateway_address : felt){
    let (_initialized) = initialized.read();
    assert _initialized = 0;

    l1_address.write(_l1_address);
    gateway_address.write(_gateway_address);

    initialized.write(1);
    return ();
}

@view
func balance_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt) -> (res : felt){
    assert_not_zero(owner);

    let (res) = balances.read(owner=owner);
    return (res=res);
}

@view
func owner_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (res : felt){
    let (res) = owners.read(token_id=token_id);
    assert_not_zero(res);

    return (res=res);
}

func _approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt){
    token_approvals.write(token_id=token_id, value=to);
    return ();
}
@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, token_id : felt){
    let (owner) = owners.read(token_id);

    assert_not_equal(owner, to);

    let (is_operator_or_owner) = _is_operator_or_owner(owner);
    assert_not_zero(is_operator_or_owner);

    _approve(to, token_id);
    return ();
}

func _is_operator_or_owner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        address : felt) -> (res : felt){
    let (caller) = get_caller_address();

    if (caller == address){
        return (res=1);
    }

    let (is_approved_for_all) = operator_approvals.read(owner=caller, operator=address);
    return (res=is_approved_for_all);
}

func _is_approved_or_owner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        spender : felt, token_id : felt) -> (res : felt){
    alloc_locals;
    let (exists) = _exists(token_id);
    assert exists = 1;

    let (owner) = owner_of(token_id);
    if (owner == spender){
        return (res=1);
    }

    let (approved_addr) = get_approved(token_id);
    if (approved_addr == spender){
        return (res=1);
    }

    let (is_operator) = is_approved_for_all(owner, spender);
    if (is_operator == 1){
        return (res=1);
    }

    return (res=0);
}

func _exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (res : felt){
    let (res) = owners.read(token_id);
    if (res == 0){
        return (res=0);
        } else {
        return (res=1);
    }
}

@storage_var
func _all_tokens_index(_token_id : felt) -> (_token_idx : felt){
}

@storage_var
func _all_tokens(_token_idx : felt) -> (_token_id : felt){
}

@storage_var
func _owned_tokens(_owner : felt, _token_idx : felt) -> (_token_id : felt){
}

@storage_var
func _owned_tokens_index(_token_id : felt) -> (_token_idx : felt){
}


func _add_token_to_all_tokens_enumeration{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _token_id: felt){

    let (last_index) = total_supply_counter.read();
    _all_tokens_index.write(_token_id=_token_id, value=last_index);
    _all_tokens.write(_token_idx=last_index, value=_token_id);

    return();
}

func _remove_token_from_all_tokens_enumeration{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _token_id: felt){

    let (total_supply_count) = total_supply_counter.read();
    tempvar last_token_index = total_supply_count - 1;

    let (token_index) = _all_tokens_index.read(_token_id);
    let (last_token_id) = _all_tokens.read(last_token_index);

    _all_tokens.write(_token_idx=token_index, value=last_token_id);
    _all_tokens_index.write(_token_id=last_token_id, value=token_index);

    _all_tokens_index.write(_token_id=_token_id, value=0);
    _all_tokens.write(_token_idx=last_token_index, value=0);

    return();
}

func _add_token_to_owner_enumeration{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _to: felt, _token_id: felt){

    let (length) = balances.read(_to);
    _owned_tokens.write(_owner=_to, _token_idx=length, value=_token_id);
    _owned_tokens_index.write(_token_id=_token_id, value=length);
    return ();
}

func _on_swap_case{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _token_id: felt, _last_token_index: felt, _token_index: felt){

    if (_last_token_index != _token_index){
        let (last_token_id) = _owned_tokens.read(_owner=_from, _token_idx=_last_token_index);

        _owned_tokens.write(_owner=_from, _token_idx=_token_index, value=last_token_id);
        _owned_tokens_index.write(_token_id=_token_id, value=_token_index);
        return ();
    }
    return ();
}

func _remove_token_from_owner_enumeration{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _token_id: felt){

    let (balance_value) = balances.read(_from);
    tempvar last_token_index = balance_value - 1;
    let (token_index) = _owned_tokens_index.read(_token_id);

    _on_swap_case(_from=_from, _token_id=_token_id, _last_token_index=last_token_index, _token_index=token_index);

    return ();
}

func _on_from_zero{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _token_id: felt
) -> (_mint_case: felt){

    if (_from == 0){
        _add_token_to_all_tokens_enumeration(_token_id);
        
        return (_mint_case=1);

    }
    return (_mint_case=0);
}

func _is_same_address{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _to: felt
) -> (_is_same: felt){
    if (_from == _to){
        return (_is_same=1);
    }
    return (_is_same=0);
}

func _on_transfer_sender_handler{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _to: felt, _token_id: felt, _mint_case: felt
){

    let (address_equality) = _is_same_address(_from=_from, _to=_to);
    let condition_check = address_equality + _mint_case;

    if (condition_check == 0){
        
        _remove_token_from_owner_enumeration(_from=_from, _token_id=_token_id);
        return ();
    }
    return ();
}

func _on_to_zero{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _to: felt, _token_id: felt
) -> (_mint_case: felt){

    if (_to == 0){
        _remove_token_from_all_tokens_enumeration(_token_id);
        
        return (_mint_case=1);

    }
    return (_mint_case=0);
}

func _on_transfer_receiver_handler{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _to: felt, _token_id: felt, _burn_case: felt
){
    let (address_equality) = _is_same_address(_from=_from, _to=_to);
    let condition_check = address_equality + _burn_case;

    if (condition_check == 0){
        
        _add_token_to_owner_enumeration(_to=_to, _token_id=_token_id) ;
        return ();
    
    }
    return ();
}

func _before_token_transfer{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _to: felt, _token_id: felt){

    let (mint_case) = _on_from_zero(_from=_from, _token_id=_token_id);
    _on_transfer_sender_handler(_from=_from, _to=_to, _token_id=_token_id, _mint_case=mint_case);
    let (burn_case) = _on_to_zero(_to=_to, _token_id=_token_id);
    _on_transfer_receiver_handler(_from=_from, _to=_to, _token_id=_token_id, _burn_case=burn_case);

    return ();
}

@view
func token_of_owner_by_index{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _owner: felt, _token_idx: felt) -> (_token_id : felt){

    let (owner_balance) = balances.read(_owner);

    assert_not_equal(owner_balance, 0);
    assert_lt(_token_idx, owner_balance);

    let (_token_id) = _owned_tokens.read(_owner=_owner, _token_idx=_token_idx);
    return (_token_id=_token_id);
}

@view
func total_supply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (total_supply_ : felt){
    let (total_supply_) = total_supply_counter.read();
    return (total_supply_=total_supply_);
}

@view
func token_by_index{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _token_idx: felt) -> (_token_id : felt){
    let (total_supply) = total_supply_counter.read();

    assert_not_equal(total_supply, 0);
    assert_lt(_token_idx, total_supply);

    let (_token_id) = _all_tokens.read(_token_idx=_token_idx);
    return (_token_id=_token_id);
}

@view
func get_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (res : felt){
    let (exists) = _exists(token_id);
    assert exists = 1;

    let (res) = token_approvals.read(token_id=token_id);
    return (res=res);
}

@view
func is_approved_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt) -> (res : felt){
    let (res) = operator_approvals.read(owner=owner, operator=operator);
    return (res=res);
}

func _mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, token_id : felt){
    assert_not_zero(to);

    let (exists) = _exists(token_id);
    assert exists = 0;

    _before_token_transfer(_from=0, _to=to, _token_id=token_id);

    let (balance) = balances.read(to);
    balances.write(to, balance + 1);

    let (total_supply) = total_supply_counter.read();
    total_supply_counter.write(total_supply + 1);

    owners.write(token_id, to);

    return ();
}

func _burn{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(token_id : felt){
    alloc_locals;

    let (local owner) = owner_of(token_id);

    _before_token_transfer(_from=owner, _to=0, _token_id=token_id);

    
    _approve(0, token_id);

    
    let (balance) = balances.read(owner);
    balances.write(owner, balance - 1);

    let (total_supply) = total_supply_counter.read();
    total_supply_counter.write(total_supply - 1);

    
    owners.write(token_id, 0);

    return ();
}

func _transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt){
    let (_owner_of) = owner_of(token_id);
    assert _owner_of = _from;

    assert_not_zero(to);

    _before_token_transfer(_from=_from, _to=to, _token_id=token_id);

    
    _approve(0, token_id);

    
    let (owner_bal) = balances.read(_from);
    balances.write(owner=_from, value=(owner_bal - 1));

    
    let (receiver_bal) = balances.read(to);
    balances.write(owner=to, value=(receiver_bal + 1));

    
    owners.write(token_id=token_id, value=to);

    return ();
}

func _set_approval_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt, approved : felt){
    assert_not_equal(owner, operator);

    
    assert approved * (1 - approved) = 0;

    operator_approvals.write(owner=owner, operator=operator, value=approved);
    return ();
}

@external
func set_approval_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt){
    let (caller) = get_caller_address();

    _set_approval_for_all(caller, operator, approved);
    return ();
}

@external
func transfer_from{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt){
    let (caller) = get_caller_address();
    _is_approved_or_owner(caller, token_id=token_id);

    _transfer(_from, to, token_id);
    return ();
}

@external
func create_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, token_id : felt){
    let (caller) = get_caller_address();
    let (_gateway_address) = gateway_address.read();
    assert caller = _gateway_address;

    _mint(owner, token_id);
    return ();
}

@external
func delete_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt){
    let (caller) = get_caller_address();
    let (_gateway_address) = gateway_address.read();
    assert caller = _gateway_address;

    _burn(token_id);
    return ();
}

@view
func get_l1_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        address : felt){
    let (address) = l1_address.read();
    return (address=address);
}