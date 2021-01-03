pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
