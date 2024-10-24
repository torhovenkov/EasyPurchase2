//
//  ExampleView.swift
//  EasyPurchase2
//
//  Created by Vladyslav Torhovenkov on 22.10.2024.
//

import SwiftUI

struct ExampleView: View {
    @StateObject private var vm = ExampleViewVM()
    
    var body: some View {
        NavigationView {
            List {
                Section("Subscribtions") {
                    ForEach(vm.subscribtions, id: \.self) { subscribtion in
                        getCell(for: subscribtion)
                    }
                }
                
                Section("Non consumbles") {
                    ForEach(vm.nonConsumables, id: \.self) { nonConsumable in
                        getCell(for: nonConsumable)
                    }
                }
                
                Section("Consumbles") {
                    ForEach(vm.consumables, id: \.self) { consumable in
                        getCell(for: consumable)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    vm.purchase()
                } label: {
                    Text(vm.buttonText)
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.vertical, 15)
                        .padding(.horizontal, 80)
                        .background(vm.isButtonDisabled ? .gray : .blue, in: .rect(cornerRadius: 12))
                        .padding(.bottom, 1)
                }
                .disabled(vm.isButtonDisabled)
            }
            .listStyle(.grouped)
            .navigationTitle("All Products")
        }
    }
    
    private func getCell(for offer: Offer) -> some View {
        Button {
            vm.select(offer)
        } label: {
            HStack {
                Text(offer.displayName)
                
                Spacer()
                
                Text(offer.displayPrice)
                
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .opacity(vm.isSelected(offer) ? 1 : 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExampleView()
}
