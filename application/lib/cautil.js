'use strict';

// const adminUserId = 'admin'
// const adminUserPasswd = 'adminpw'

// org1 ca 객체화- 연결
exports.buildCAClient = (FabricCAServices, ccp, caHostName) => {
    const caInfo = ccp.certificateAuthorities[caHostName];

    const caTLSCACerts = caInfo.tlsCACerts.pem;
    const caClient = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

    console.log(`Built a CA Client name ${caInfo.caName}`);
    return caClient;
};

// admin 인증서 생성
exports.enrollAdmin = async (caClient, wallet, orgMspId, adminUserId, adminUserPasswd) => {
    try {
        const identity = await wallet.get(adminUserId);
        if(identity) {
            console.log('An identity for the admin user already exists in the wallet');
            throw new Error(`An identity for the admin user already exists in the wallet`);
            return;
        }

        const enrollment = await caClient.enroll({ enrollmentID: adminUserId, enrollmentSecret: adminUserPasswd});

        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: orgMspId,
            type: 'X.509',
        };

        await wallet.put(adminUserId, x509Identity);
        console.log('Sucessfully enrolled admin user and imported it into the wallet');

    } catch (error) {
        throw new Error(`Failed to enroll admin user: ${error}`);
    }
}
// user 인증서 생성
exports.registerAndEnrollUser = async ( caClient, wallet, orgMspId, adminUserId, userId, role, affiliation) => {
    try {
        const userIdentity = await wallet.get(userId);
        if(userIdentity) {
            console.log(`An identity for the user ${userId} already exists in the wallet`);
            throw new Error(`An identity for the user ${userId} already exists in the wallet`);
            return;
        }

        const adminIdentity = await wallet.get(adminUserId);
        if(!adminIdentity) {
            console.log('An identity for the admin user does not exist in the wallet');
            console.log('Enroll the admin user before retrying');
            throw new Error('An identity for the admin user does not exist in the wallet');
            return;
        }

        const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
        const adminUser = await provider.getUserContext(adminIdentity, adminUserId);

        // 관리자가 등록해주는 부분
        const secret = await caClient.register({
            affiliation: affiliation, // 부서
            enrollmentID: userId,
            role: role // 역활
        }, adminUser);

        // 사용자가 등록하는 부분
        const enrollment = await caClient.enroll({
            enrollmentID: userId,
            enrollmentSecret:secret
        });

        // x.509 구조체 생성
        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: orgMspId,
            type: 'X.509',
        };

        // x.509 인증서를 wallet디렉토리에 저장
        await wallet.put(userId, x509Identity);
        console.log(`Successfully registered and enrolled user ${userId} and imported it into the wallet`);

    } catch (error) {
        console.error(`Failed to register user : ${error}`);
        throw new Error(`Failed to register user : ${error}`);

    }
}
