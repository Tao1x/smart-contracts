### encodeParams.js

- First argument is comma separated string with argument types
- Second argument is comma separated string with argument values

- Example of transferring 1500000 tokens to `0xf3B39c28bF4c5c13346eEFa8F90e88B78A610381`: 
```angular2html
$ node encodeParams.js 'address,uint256' '0xf3B39c28bF4c5c13346eEFa8F90e88B78A610381,1500000000000000000000000'
```

---

### Congress submit proposal and vote

- _**Step 1:**_ Select method to execute and destination contract
- _**Step 2:**_ Generate calldata (explained in `encodeParams.js` section)
- _**Step 3:**_ Congress can execute multiple methods in the same transaction, but highly 
recommended is to stick with the one. (That is the reason why always array is accepted)
- _**Step 4:**_ Call the function:
```
function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    )
```
<br/>

- _Step 4.1:_ targets is array of destination targets (where transaction should go)
- _Step 4.2:_ values are ETH values for the corresponding targets if there's any payable method called
- _Step 4.3:_ signatures are signatures of methods being called (Ex: "transfer(address,uint256)")
- _Step 4.4:_ calldatas is the array of calldatas got from Step 2.
- _Step 4.5:_ description is array of descriptions what is done in the actions

<br/>

- _**Step 5:**_ After method propose is called (best through etherscan) members can vote
- _**Step 6:**_ During propose method event is emitted with proposalId which is used for voting
- _**Step 7:**_ Members can vote
- _**Step 8:**_ Once quorum is reached any member can execute proposal

---
