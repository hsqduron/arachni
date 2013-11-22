require 'spec_helper'

describe Arachni::Support::Signature do
    def string_with_noise
        <<-END
                This #{rand(999999)} is a test.
                Not #{rand(999999)} really sure what #{rand(999999)} else to put here...
                #{rand(999999)}
        END
    end

    def different_string_with_noise
        <<-END
                This #{rand(999999)} is a different test.
        END
    end

    let(:signature) { described_class.new( string_with_noise ) }

    describe '#initialize' do
        describe 'option' do
            describe :threshold do
                it 'sets the maximum difference in tokens when performing comparisons' do
                    seed1 = 'test this here 1'
                    seed2 = 'test that here 2'

                    s  = described_class.new( seed1, threshold: 1 )
                    s1 = described_class.new( seed2 )
                    s.should_not be_similar s1

                    s  = described_class.new( seed1, threshold: 2 )
                    s1 = described_class.new( seed2 )
                    s.should_not be_similar s1

                    s  = described_class.new( seed1, threshold: 5 )
                    s1 = described_class.new( seed2 )
                    s.should be_similar s1

                    s  = described_class.new( seed1, threshold: 6 )
                    s1 = described_class.new( seed2 )
                    s.should be_similar s1
                end

                context 'when not a number' do
                    it 'raises ArgumentError' do
                        expect do
                            described_class.new( 'test', threshold: 'stuff' )
                        end.to raise_error ArgumentError
                    end
                end
            end
        end
    end

    describe '#refine' do
        it 'removes noise from the signature' do
            string_with_noise.should_not == string_with_noise

            signature1 = described_class.new( string_with_noise )

            10.times{ signature1 = signature1.refine( string_with_noise ) }

            signature2 = described_class.new( string_with_noise )
            10.times{ signature2 = signature2.refine( string_with_noise ) }

            signature1.should == signature2
        end

        it 'returns a new signature instance' do
            signature1 = described_class.new( string_with_noise )
            signature1.refine( string_with_noise ).object_id.should_not == signature1.object_id
        end
    end

    describe '#refine!' do
        it 'destructively removes noise from the signature' do
            string_with_noise.should_not == string_with_noise

            signature1 = described_class.new( string_with_noise )
            10.times{ signature1.refine!( string_with_noise ) }

            signature2 = described_class.new( string_with_noise )
            10.times{ signature2.refine!( string_with_noise ) }

            signature1.should == signature2
        end

        it 'returns self' do
            signature = described_class.new( string_with_noise )
            signature.refine!( string_with_noise ).object_id.should == signature.object_id
        end
    end

    describe '#distance' do
        it 'returns the Levenshtein distance between signature tokens' do
            signature1 = described_class.new( string_with_noise )
            signature2 = described_class.new( string_with_noise )
            signature3 = described_class.new( different_string_with_noise )
            signature4 = described_class.new( different_string_with_noise )

            signature1.distance( signature2 ).should == 4
            signature2.distance( signature2 ).should == 0

            signature3.distance( signature4 ).should == 1
            signature4.distance( signature4 ).should == 0
            signature1.distance( signature3 ).should == 44
        end
    end

    describe '#differences_between' do
        it 'returns amount of differences between signature tokens' do
            signature1 = described_class.new( string_with_noise )
            signature2 = described_class.new( string_with_noise )
            signature3 = described_class.new( different_string_with_noise )
            signature4 = described_class.new( different_string_with_noise )

            signature1.differences_between( signature2 ).should == 8
            signature2.differences_between( signature2 ).should == 0

            signature3.differences_between( signature4 ).should == 2
            signature4.differences_between( signature4 ).should == 0
            signature1.differences_between( signature3 ).should == 18
        end
    end

    describe '#==' do
        context 'when the signature are identical' do
            it 'returns true' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2.refine!( string_with_noise ) }

                signature1.should == signature2
            end
        end

        context 'when the signature are not identical' do
            it 'returns false' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( different_string_with_noise )
                10.times{ signature2.refine!( different_string_with_noise ) }

                signature1.should_not == signature2
            end
        end
    end

    describe '#dup' do
        it 'returns a duplicate instance' do
            signature.dup.should == signature
            signature.dup.object_id.should_not == signature.object_id
        end
    end
end
