import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Venue } from '../typechain-types';
const utils = ethers.utils;

describe('Venue', function () {
    let venue: Venue, owner, user: any;
    const venueName = utils.formatBytes32String('Auditorio Nacional');
    const venueAddress = 'Av. Paseo de la Reforma 50, Polanco V Secc, Miguel Hidalgo, 11560 Ciudad de México, CDMX';
    const capacity = 10000;
    const phone = '55 9138 1350';
    const description = 'El Auditorio Nacional es un centro de espectáculos en la Ciudad de México. Se trata del principal recinto de presentaciones en ese país y uno de los más importantes en el mundo, según diversos medios especializados.​';
    const website = 'http://www.auditorio.com.mx/';
    const email = 'auditorio@auditorio.com.mx';
    
    before(async function () {
        // Contracts are deployed using the first signer/account by default
        [owner, user] = await ethers.getSigners();

        const Venue = await ethers.getContractFactory("Venue");
        venue = await Venue.deploy();
    });

    it('Should add new venue and check if the venue exists', async function() {
        await venue.addVenue(venueName, venueAddress, capacity, phone, description, website, email);
        
        const exists = await venue.venueExists(venueName);

        expect(exists).to.equal(true);
    });
    
    it('Should not add new venue if this already exists', async function() {
        await expect(venue.addVenue(venueName, venueAddress, capacity, phone, description, website, email))
        .to.be.revertedWith('Venue already exists');
    });

    it('Should not add new venue if caller is not admin', async function() {
        await expect(venue.connect(user).addVenue(venueName, venueAddress, capacity, phone, description, website, email))
        .to.be.revertedWith('Caller is not admin');
    });

    it('Should get venue info', async function() {
        const venueInfo = await venue.getVenue(venueName);

        expect(venueInfo[0]).to.equal(venueName);
        expect(venueInfo[1]).to.equal(venueAddress);
        expect(venueInfo[2]).to.equal(capacity);
    });

    it('Should not get venue info if the venue is not registered', async function() {
        const venueName = utils.formatBytes32String('Estadio Azteca');

        await expect(venue.getVenue(venueName)).to.be.revertedWith('Venue does not exists');
    });

    it('Should get venue list', async function() {
        const venueList = await venue.getVenues();

        expect(venueList.length).to.equal(1);
    });

    it('Should not remove venue if caller is not admin', async function() {
        await expect(venue.connect(user).removeVenue(venueName)).to.be.revertedWith('Caller is not admin');
    });

    it('Should not remove venue if the venue is not registered', async function() {
        const venueName = utils.formatBytes32String('Estadio Azteca');

        await expect(venue.removeVenue(venueName)).to.be.revertedWith('Venue does not exists');
    });

    it('Should remove venue', async function() {
        await venue.removeVenue(venueName);

        const exists = await venue.venueExists(venueName);

        expect(exists).to.equal(false);
    });

    it('Should not execute remove function if venue list is empty', async function() {
        await expect(venue.removeVenue(venueName)).to.be.revertedWith('Empty list');
    });
});