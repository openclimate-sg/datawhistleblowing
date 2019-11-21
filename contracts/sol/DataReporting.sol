pragma solidity ^0.5.11;

import { Semaphore } from "./semaphore/Semaphore.sol";
import { SafeMath } from "./SafeMath.sol";

contract DataReporting {
    using SafeMath for uint256;

    // The Semaphore contract
    Semaphore public semaphore;

    address payable public company;
    address payable public investigator;

    // The mapping of report nums to data hashes
    mapping (uint256 => bytes32) public reportNumToReportHash;

    uint256 public nextReportNum;

    // The deposit amount
    uint256 public depositAmtWei;

    // The number of deposits to lockup
    uint256 public lockupNum;

    // The maximum number of reports
    uint256 public maxReportNum;

    // The total amount locked up
    uint256 public totalLockedWei;

    // The amount currently seized when the whistle is blown
    uint256 public totalSeizedWei;

    // The whistleblower's specified reward address
    address payable whistleblowerRewardAddress;

    constructor(
        address _semaphore,
        uint256 _depositAmtWei,
        uint256 _lockupNum,
        uint256 _maxReportNum,
        address payable _company,
        address payable _investigator
    ) public {
        require(_maxReportNum >= _lockupNum, "DataReporting: _maxReportNum must be gte than _lockupNum");
        semaphore = Semaphore(_semaphore);
        depositAmtWei = _depositAmtWei;
        lockupNum = _lockupNum;
        company = _company;
        investigator = _investigator;
    }

    /*
     * @param _identityCommitment The Semaphore identity commitment
     * Allows a user to register their identity into Semaphore
     */
    function insertIdentity(uint256 _identityCommitment) public {
        semaphore.insertIdentity(_identityCommitment);
    }

    function reportData(bytes32 _reportHash) public payable {
        require(msg.sender == company, "DataReporting: only the company can report data");
        // Ensure that the user has deposited the corrrect amount of wei only
        // if the current report is lower than the number of minimum lockups
        if (nextReportNum < lockupNum) {
            require(msg.value == depositAmtWei, "DataReporting: wrong deposit amount");
            totalLockedWei = totalLockedWei.add(msg.value);
        }

        // Store the report hash
        reportNumToReportHash[nextReportNum] = _reportHash;

        // Increment the report index
        nextReportNum ++;

        semaphore.addExternalNullifier(uint256(_reportHash));
    }

    /*
     * @param _signal The signal to broadcast
     * @param _a The pi_a zk-SNARK proof data
     * @param _b The pi_b zk-SNARK proof data
     * @param _c The pi_c zk-SNARK proof data
     * @param _input The public signals to the zk-SNARK proof.
     * Allows a registered user to anonymously broadcast a signal.
     */
    function blowWhistle(
        address payable _rewardAddress,
        bytes memory _signal,
        uint[2] memory _a,
        uint[2][2] memory _b,
        uint[2] memory _c,
        uint[4] memory _input // (root, nullifiers_hash, signal_hash, external_nullifier)
    ) public {

        require(totalLockedWei > totalSeizedWei, "DataReporting: the amount to seize must be smaller than the amount locked");
        totalSeizedWei = totalLockedWei;

        require(
            whistleblowerRewardAddress == 0x0000000000000000000000000000000000000000,
            "DataReporting: only one whistleblower is currently supported"
        );

        whistleblowerRewardAddress = _rewardAddress;

        semaphore.broadcastSignal(
            _signal,
            _a,
            _b,
            _c,
            _input
        );
    }

    function retrievableDeposit() public view returns (uint256) {
        return address(this).balance.sub(totalLockedWei).sub(totalSeizedWei);
    }

    /*
     * Transfer the unseized deposit to the company. Only the company can call
     * this function.
     */
    function retrieveDeposit() public {
        require(msg.sender == company, "DataReporting: only the company can retrieve their deposit");

        uint256 reclaimable = retrievableDeposit();

        company.transfer(reclaimable);
    }

    /*
     * Transfer the deposit to the investigator. Only the investigator can call
     * this function and this 
     */
    function seizeDeposit() public {
        require(msg.sender == investigator, "DataReporting: only the investigator can seize the deposit");

        uint256 halfSeized = totalSeizedWei.div(2);
        investigator.transfer(halfSeized);
        whistleblowerRewardAddress.transfer(halfSeized);
        totalSeizedWei = 0;
    }

    /*
     * Unseized any seized deposits. Only the investigator can call this function.
     */
    function unseizeDeposit() public {
        require(msg.sender == investigator, "DataReporting: only the investigator can unfreeze the company's deposit");
        require(totalSeizedWei > 0, "DataReporting: there must be seized funds");

        totalSeizedWei = 0;
    }

    function getIdentityCommitments() public view returns (uint256[] memory) { 
        return semaphore.leaves(semaphore.id_tree_index());
    }

    function getExternalNullifiers() public view returns (uint256[] memory) {
        uint256 max = semaphore.getNextExternalNullifierIndex();
        uint256[] memory externalNullifiers = new uint256[](max);
        for (uint256 i=0; i < max; i++) {
            externalNullifiers[i] = semaphore.getExternalNullifierByIndex(i);
        }

        return externalNullifiers;
    }
}
