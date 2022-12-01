%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import deploy
from starkware.cairo.common.bool import FALSE
from starkware.starknet.common.syscalls import get_block_timestamp


const BRIDGE_MODE_WITHDRAW = 1;
const ETH_ADDRESS = 0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;
const JEDI_ROUTER = 0x02bcc885342ebbcbcd170ae6cafa8a4bed22bb993479f49806e72d96af94c965;
const TOKEN_CLASS_HASH = 0x210a1564940ea06fbe928d2b84ead33e178d7cc6d0e0547e015441fcba5cedc;

@contract_interface
namespace IBridgedERC20 {
     func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func decimals() -> (decimals: felt) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }

    func mint(to: felt, amount: Uint256){
    }
}


@contract_interface
namespace IRouter {
func swap_exact_tokens_for_tokens(amountIn: Uint256, amountOutMin: Uint256, path_len: felt, path: felt*, to: felt, deadline: felt) -> (amounts_len: felt, amounts: Uint256*){
}

}




@storage_var
func initialized() -> (res : felt){
}


@storage_var
func l1_gateway() -> (res : felt){
}

@storage_var
func salt() -> (value: felt) {
}


@storage_var
func zero() -> (res: Uint256) {
}

@view
func get_l1_gateway{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res : felt){
    let (res) = l1_gateway.read();
    return (res=res);
}

@storage_var
func token_class_hash() -> (res: felt) {
}


@storage_var
func custody(l1_token_address : felt, token_id : felt) -> (res : felt){
}

@storage_var
func token_address() -> (res : felt){
}


@storage_var
func collateral_data(l1_token_address : felt, token_id : felt) -> (res : felt){
}

@view
func get_collateral_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _l1_token_address : felt, _token_id : felt) -> (res : felt){
    let (res) = collateral_data.read(
        l1_token_address=_l1_token_address, token_id=_token_id);
    return (res=res);
}


@external
func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _l1_gateway : felt,token_class_hash:felt){
    let (is_initialized) = initialized.read();
    assert is_initialized = 0;
    let (contract_address) = get_contract_address();
    l1_gateway.write(_l1_gateway);
    let (current_salt) = salt.read();
    let (ptr) = alloc();
    
    // Populate some values in the array.
    assert [ptr] = 'NFT ROKZ';
    assert [ptr + 1] = 'NTZ';
    assert [ptr + 2] = contract_address;
  




    let (deployed_address) = deploy(
        class_hash=token_class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=3,
        constructor_calldata=ptr,
        deploy_from_zero=FALSE,
    );
    salt.write(value=current_salt + 1);
    token_address.write(value=deployed_address);
    initialized.write(1);

    return ();
}


@l1_handler
func bridge_from_mainnet{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_address : felt, _owner : felt, _l1_token_address : felt,
        _token_id : felt,_floor_price: Uint256,_require_token_address:felt,counter: felt){
        alloc_locals;
    let (res) = l1_gateway.read();
  //  assert from_address = res;

    let (currentCustody) = custody.read(l1_token_address=_l1_token_address, token_id=_token_id);
    assert currentCustody = 0;

    collateral_data.write(
        l1_token_address=_l1_token_address,
        token_id=_token_id,
        value=_owner);

    isclaimed.write(counter,value=1);
    require_token.write(counter,value=_require_token_address);
    store_amount.write(counter,_floor_price,value=_owner);
    return();

   
}


@external
func claim_loan{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id:felt,amount:Uint256,owner:felt
) {
alloc_locals;
    let (check) = isclaimed.read(id);
    assert_not_zero(check);
    let (amount_valid) = store_amount.read(id,amount);
    assert_not_zero(amount_valid);
    let (require_tokenn) = require_token.read(id);
    if(amount_valid == owner){
        let (deadline) = get_block_timestamp();
        let (zer) = zero.read();
        let (local path : felt*) = alloc();
        assert [path] = ETH_ADDRESS;
        assert [path+1] = require_tokenn;
        let path_len = 2;
        IBridgedERC20.approve(contract_address = ETH_ADDRESS,spender= JEDI_ROUTER,amount= amount);
        IRouter.swap_exact_tokens_for_tokens(contract_address = JEDI_ROUTER, amountIn = amount, amountOutMin = zer, path_len = path_len, path = path, to = owner, deadline = deadline);
        return ();
    
    }
    return();

    
}

@external
func bridge_debug{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_address : felt, _owner : felt, _l1_token_address : felt,
        _token_id : felt,_floor_price: Uint256,_require_token_address:felt){
        alloc_locals;
    let (res) = l1_gateway.read();
  //  assert from_address = res;

    let (currentCustody) = custody.read(l1_token_address=_l1_token_address, token_id=_token_id);
    assert currentCustody = 0;

    collateral_data.write(
        l1_token_address=_l1_token_address,
        token_id=_token_id,
        value=_owner);

    let (deadline) = get_block_timestamp();
    let (zer) = zero.read();
    let (local path : felt*) = alloc();
    assert [path] = ETH_ADDRESS;
    assert [path+1] = _require_token_address;
    let path_len = 2;
    IBridgedERC20.approve(contract_address = ETH_ADDRESS,spender= JEDI_ROUTER,amount= _floor_price);
    IRouter.swap_exact_tokens_for_tokens(contract_address = JEDI_ROUTER, amountIn = _floor_price, amountOutMin = zer, path_len = path_len, path = path, to = _owner, deadline = deadline);
    return ();
}




@storage_var
func bridge_back_events(l1_token_address : felt, l2_token_address : felt, owner : felt, index : felt) -> (token_id : felt){
}

@storage_var
func bridge_back_event_count(l1_token_address : felt, l2_token_address : felt, owner : felt) -> (count : felt){
}

@storage_var
func require_token(id:felt) -> (res: felt) {
}



@storage_var
func isclaimed(id: felt) -> (res: felt) {
}



@storage_var
func store_amount(id: felt,amount: Uint256) -> (res: felt) {
}


@view
func get_bridge_back_event_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        l1_token_address : felt, l2_token_address : felt, owner : felt) -> (count : felt){
    let (count) = bridge_back_event_count.read(l1_token_address=l1_token_address, l2_token_address=l2_token_address, owner=owner);
    return (count=count);
}

@view
func get_bridge_back_event{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        l1_token_address : felt, l2_token_address : felt, owner : felt, index : felt) -> (token_id : felt){
    let (token_id) = bridge_back_events.read(l1_token_address=l1_token_address, l2_token_address=l2_token_address, owner=owner, index=index);
    return (token_id=token_id);
}






@storage_var
func balance() -> (res: felt) {
}


@external
func stake{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: Uint256
) {
    let (caller_address) = get_caller_address();
    let (contract_address) = get_contract_address();
    let (token_addr) = token_address.read();
    IBridgedERC20.transferFrom(contract_address=ETH_ADDRESS,sender=caller_address,recipient=contract_address,amount=amount);
    IBridgedERC20.mint(contract_address=token_addr,to=caller_address,amount=amount);
    return();




}


@external
func increase_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    amount: felt
) {
    with_attr error_message("Amount must be positive. Got: {amount}.") {
        assert_nn(amount);
    }

    let (res) = balance.read();
    balance.write(res + amount);
    return ();
}

@view
func get_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = balance.read();
    return (res,);
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    balance.write(0);
    return ();
}
