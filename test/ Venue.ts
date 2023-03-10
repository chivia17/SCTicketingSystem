import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Venue } from '../typechain-types';
const utils = ethers.utils;

describe('Venue', function () {
    let venue: Venue, owner, user;

    beforeEach(async function () {
        // Contracts are deployed using the first signer/account by default
        [owner, user] = await ethers.getSigners();

        const Venue = await ethers.getContractFactory("Venue");
        venue = await Venue.deploy();
    });

    it('Should add new venue and check if the venue exists', async function() {
        const venueName = utils.formatBytes32String('Auditorio Nacional');
        const venueAddress = 'Av. Paseo de la Reforma 50, Polanco V Secc, Miguel Hidalgo, 11560 Ciudad de México, CDMX';
        const capacity = 10000;
        const phone = '55 9138 1350';
        const description = 'El Auditorio Nacional es un centro de espectáculos en la Ciudad de México. Se trata del principal recinto de presentaciones en ese país y uno de los más importantes en el mundo, según diversos medios especializados.​';
        const website = 'http://www.auditorio.com.mx/';
        const email = 'auditorio@auditorio.com.mx';


        await venue.addVenue(venueName, venueAddress, capacity, phone, description, website, email);
        
        const exists = await venue.venueExists(venueName);

        expect(exists).to.equal(true);
    })
});