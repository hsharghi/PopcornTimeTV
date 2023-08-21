//
//  TermsOfServiceView.swift
//  PopcornTimetvOS SwiftUI
//
//  Created by Alexandru Tudose on 19.06.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Binding var tosAccepted: Bool
    
    var body: some View {
        VStack(spacing: 50) {
            Text("Terms Of Service")
            ScrollView {
                Text(longText)
                    .frame(maxWidth: 1200)
                    .font(.callout)
            }
            .padding()
            
            HStack(spacing: 50) {
                leaveButton
                acceptButton
            }
        }
    }
    
    @ViewBuilder
    var leaveButton: some View {
        Button(action: {
            exit(0)
        }, label: {
            Text("Leave")
        })
    }
    
    @ViewBuilder
    var acceptButton: some View {
        Button(action: {
            Session.tosAccepted = true
            tosAccepted = true
        }, label: {
            Text("Accept")
        })
    }
    
    
    let longText: LocalizedStringKey = """
        Your Acceptance

        By using the ‘Popcorn Time’ app you signify your agreement to (1) these terms and conditions (the 'Terms of Service').

        Privacy Policy

        You understand that by using ‘Popcorn Time’, you may encounter material that you may deem to be offensive, indecent, or objectionable, and that such content may or may not be identified as having explicit material. 'Popcorn Time' will have no liability to you for such material – you agree that your use of 'Popcorn Time' is at your sole risk.

        Disclaimers

        YOU EXPRESSLY AGREE THAT YOUR USE OF 'POPCORN TIME' IS AT YOUR SOLE RISK. 'POPCORN TIME' AND ALL PRODUCTS ARE PROVIDED TO YOU 'AS IS' WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. TO THE FULLEST EXTENT POSSIBLE UNDER APPLICABLE LAWS, YIFY DISCLAIMS ALL WARRANTIES, EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO: IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, OR OTHER VIOLATIONS OF RIGHTS.

        Limitation of Liability

        'POPCORN TIME' IS NOT RESPONSIBLE FOR ANY PROBLEMS OR TECHNICAL MALFUNCTION OF ANY WEBSITE, NETWORK, COMPUTER SYSTEMS, SERVERS, PROVIDERS, COMPUTER EQUIPMENT, OR SOFTWARE, OR FOR ANY FAILURE DUE TO TECHNICAL PROBLEMS OR TRAFFIC CONGESTION ON THE INTERNET, INCLUDING ANY INJURY OR DAMAGE TO USERS OR TO ANY COMPUTER OR OTHER DEVICE ON OR THROUGH WHICH 'POPCORN TIME' IS PROVIDED. UNDER NO CIRCUMSTANCES WILL 'POPCORN TIME' BE LIABLE FOR ANY LOSS OR DAMAGE, INCLUDING PERSONAL INJURY OR DEATH, RESULTING FROM YOUR USE OF 'POPCORN TIME'.

        Source Material

        MOVIES AND TV SHOWS ARE NOT HOSTED ON ANY SERVER AND ARE STREAMED USING THE P2P BIT TORRENT PROTOCOL. ALL MOVIES AND TV SHOWS ARE PULLED IN FROM OPEN PUBLIC APIS. WATCHING A MOVIE/SHOW WITH THIS APPLICATION MAY MEAN YOU ARE COMMITTING COPYRIGHT VIOLATIONS DEPENDING ON YOUR COUNTRY'S LAWS. WE DO NOT TAKE ANY RESPONSIBILITIES.

        Ability to Accept Terms of Service

        By using 'Popcorn Time' or accessing this site you affirm that you are either more than 18 years of age, or an emancipated minor, or possess legal parental or guardian consent, and are fully able and competent to enter into the terms, conditions, obligations, affirmations, representations, and warranties set forth in these Terms of Service, and to abide by and comply with these Terms of Service. In any case, you affirm that you are over the age of 13, as the Service is not intended for children under 13. If you are under 13 years of age, then please do not use the Service. There are lots of other great web sites for you. Talk to your parents about what sites are appropriate for you.
        """
}

struct AcceptTermsOfService: ViewModifier {
    @State var tosAccepted = Session.tosAccepted
    
    func body(content: Content) -> some View {
        if tosAccepted {
            content
        } else {
            TermsOfServiceView(tosAccepted: $tosAccepted)
        }
    }
}

struct TermsOfServiceView_Previews: PreviewProvider {
    static var previews: some View {
        TermsOfServiceView(tosAccepted: .constant(false))
    }
}
