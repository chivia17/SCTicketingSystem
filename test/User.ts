import { expect } from 'chai';
import { ethers } from 'hardhat';
import { User } from '../typechain-types';
const utils = ethers.utils;

describe('User', function () {
    let userInstance: User, owner: any, user: any, promoter: any;
    const name = 'Raul Ziranda Gonzalez';
    const age = '29';
    const email = 'raulzi.dev@gmail.com';
    const phoneNumber = '4341150678';
    const photoHash = 'mtwirsqawjuoloq2gvtyug2tc3jbf5htm2zeo4rsknfiv3fdp46a';
    const voiceIdHash = 'mtwirsqawjuoloq2gvtyug2tc3jbf5htm2zeo4rsknfiv3fdp46a';
    const faceIdHash = 'QmTtDqWzo179ujTXU7pf2PodLNjpcpQQCXhkiQXi6wZvKd';

    const promoterName = 'Live Nation';
    const promoterEmail = 'promoter@gmail.com';
    const promoterPhoneNumber = '5531143454';
    const promoterWebsite = 'https://www.livenation.lat';
    const promoterVoiceIdHash = 'mtwirsqawjuoloq2gvtyug2tc3jbf5htm2zeo4rsknfiv3fdp46a';
    const promoterFaceIdHash = 'QmTtDqWzo179ujTXU7pf2PodLNjpcpQQCXhkiQXi6wZvKd';

    before(async function() {
        // Contracts are deployed using the first signer/account by default
        [owner, user, promoter] = await ethers.getSigners();

        const UserInstance = await ethers.getContractFactory("User");
        userInstance = await UserInstance.deploy();
    });

    it('Should add new user', async function() {
        await userInstance.addUser(utils.formatBytes32String(name),
            age,
            utils.formatBytes32String(email),
            phoneNumber,
            photoHash,
            voiceIdHash,
            faceIdHash);
        
        const exists = await userInstance.userExists(owner.address);

        expect(exists).to.equal(true);
    });

    it('Should not add new user if the address is already register', async function() {
        await expect(userInstance.addUser(utils.formatBytes32String(name),
            age,
            utils.formatBytes32String(email),
            phoneNumber,
            photoHash,
            voiceIdHash,
            faceIdHash)).to.be.revertedWith('User already registered');
    });

    it('Should add new promoter', async function() {
        await userInstance.addPromoter(promoter.address,
            utils.formatBytes32String(promoterName),
            utils.formatBytes32String(promoterEmail),
            promoterPhoneNumber,
            promoterWebsite,
            promoterVoiceIdHash,
            promoterFaceIdHash);
        
        const exists = await userInstance.promoterExists(promoter.address);

        expect(exists).to.equal(true);
    });

    it('Should not add new promoter if caller is not admin', async function() {
        await expect(userInstance.connect(user).addPromoter(promoter.address,
            utils.formatBytes32String(promoterName),
            utils.formatBytes32String(promoterEmail),
            promoterPhoneNumber,
            promoterWebsite,
            promoterVoiceIdHash,
            promoterFaceIdHash)).to.be.revertedWith('Caller is not admin');
    });

    it('Should not add new promoter if promoter address is address zero', async function() {
        await expect(userInstance.addPromoter(ethers.constants.AddressZero,
            utils.formatBytes32String(promoterName),
            utils.formatBytes32String(promoterEmail),
            promoterPhoneNumber,
            promoterWebsite,
            promoterVoiceIdHash,
            promoterFaceIdHash)).to.be.revertedWith('Invalid user address');
    });
    
    it('Should not add new promoter if promoter already exists', async function() {
        await expect(userInstance.addPromoter(promoter.address,
            utils.formatBytes32String(promoterName),
            utils.formatBytes32String(promoterEmail),
            promoterPhoneNumber,
            promoterWebsite,
            promoterVoiceIdHash,
            promoterFaceIdHash)).to.be.revertedWith('Promoter already registered');
    });

    it('Should login user', async function() {
        const message = 'I am signing my one-time nonce';
        const messageHash = utils.solidityKeccak256(['string'], [message]);
        const signature = await owner.signMessage(utils.arrayify(messageHash));
        const sig = utils.splitSignature(signature);

        const login = await userInstance.login(1, sig.v, sig.r, sig.s, messageHash);

        expect(login).to.equal(true);
    });

    it('Should not login if user try to enter with signature make for another user', async function() {
        const message = 'I am signing my one-time nonce';
        const messageHash = utils.solidityKeccak256(['string'], [message]);
        const signature = await owner.signMessage(utils.arrayify(messageHash));
        const sig = utils.splitSignature(signature);

        await expect(userInstance.connect(user).login(1, sig.v, sig.r, sig.s, messageHash)).to.be.revertedWith('Login forbidden');
    });
});